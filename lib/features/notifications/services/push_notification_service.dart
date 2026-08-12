import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/notification_repository.dart';
import 'notification_navigation_service.dart';

class PushEnvelope {
  const PushEnvelope({
    required this.type,
    required this.payload,
    this.notificationId,
  });

  final String type;
  final Map<String, dynamic> payload;
  final String? notificationId;

  factory PushEnvelope.fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Missing notification type');
    }
    final rawPayload = data['payload'];
    final decoded = rawPayload is String && rawPayload.isNotEmpty
        ? jsonDecode(rawPayload)
        : const <String, dynamic>{};
    if (decoded is! Map) throw const FormatException('Invalid payload');
    return PushEnvelope(
      type: type,
      payload: Map<String, dynamic>.from(decoded),
      notificationId: data['notificationId'] as String?,
    );
  }

  String encode() => jsonEncode({
    'type': type,
    'payload': jsonEncode(payload),
    if (notificationId != null) 'notificationId': notificationId,
  });
}

class PushNotificationService extends GetxService {
  PushNotificationService({
    required NotificationRepository repository,
    required AuthController authController,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _repository = repository,
       _authController = authController,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final NotificationRepository _repository;
  final AuthController _authController;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Worker? _authWorker;
  String? _registeredToken;
  PushEnvelope? _initialEnvelope;
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'ndeli_notifications',
    'Notifications Ndeli',
    description: 'Quêtes, validations, alliés et paiements',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final raw = response.payload;
        if (raw == null) return;
        try {
          _open(
            PushEnvelope.fromData(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            ),
          );
        } catch (_) {
          _openFallback();
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForeground,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteOpen,
    );
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      try {
        _initialEnvelope = PushEnvelope.fromData(initial.data);
      } catch (_) {
        _initialEnvelope = const PushEnvelope(type: '', payload: {});
      }
    }
    _authWorker = ever(_authController.user, (_) {
      if (_authController.isAuthenticated) registerCurrentDevice();
    });
    if (_authController.isAuthenticated) await registerCurrentDevice();
  }

  void openInitialMessage() {
    final envelope = _initialEnvelope;
    _initialEnvelope = null;
    if (envelope == null) return;
    if (envelope.type.isEmpty) {
      _openFallback();
    } else {
      _open(envelope);
    }
  }

  Future<void> registerCurrentDevice() async {
    if (!_authController.isAuthenticated) return;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      if (kDebugMode) debugPrint('Ndeli FCM token: $token');
      await _register(token);
      _tokenSubscription ??= _messaging.onTokenRefresh.listen((token) {
        if (kDebugMode) debugPrint('Ndeli FCM token refreshed: $token');
        _register(token);
      });
    } catch (_) {
      // Push is optional and must never block authentication or app startup.
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final token = _registeredToken;
    if (token == null) return;
    try {
      await _repository.removeDeviceToken(token);
    } catch (_) {
      // Best effort: FCM invalid-token cleanup handles abandoned tokens too.
    } finally {
      _registeredToken = null;
    }
  }

  Future<void> _register(String token) async {
    if (!_authController.isAuthenticated || token == _registeredToken) return;
    try {
      await _repository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      _registeredToken = token;
    } catch (_) {
      // The next login/app launch/token rotation retries registration.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    PushEnvelope envelope;
    try {
      envelope = PushEnvelope.fromData(message.data);
    } catch (_) {
      return;
    }
    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? 'Ouvrez Ndeli pour voir les détails.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ndeli_notifications',
          'Notifications Ndeli',
          channelDescription: 'Quêtes, validations, alliés et paiements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: envelope.encode(),
    );
  }

  void _handleRemoteOpen(RemoteMessage message) {
    try {
      _open(PushEnvelope.fromData(message.data));
    } catch (_) {
      _openFallback();
    }
  }

  void _open(PushEnvelope envelope) {
    if (envelope.notificationId != null && _authController.isAuthenticated) {
      _repository.markRead(envelope.notificationId!).catchError((_) {});
    }
    Get.find<NotificationNavigationService>().openType(
      envelope.type,
      envelope.payload,
    );
  }

  void _openFallback() =>
      Get.find<NotificationNavigationService>().openType('unknown', const {});

  @override
  void onClose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _tokenSubscription?.cancel();
    _authWorker?.dispose();
    super.onClose();
  }
}
