import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../onboarding/controllers/guided_tour_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../social/controllers/allies_controller.dart';
import '../controllers/notification_controller.dart';
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

String? questIdToRefresh(PushEnvelope envelope) {
  if (envelope.type != 'quest_ally_invite_accepted') return null;
  final questId = envelope.payload['questId'];
  return questId is String && questId.isNotEmpty ? questId : null;
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

  static const _permissionAskedKey = 'push_permission_asked';
  bool _asking = false;

  Future<void> registerCurrentDevice() async {
    if (!_authController.isAuthenticated) return;
    try {
      final current = await _messaging.getNotificationSettings();
      if (current.authorizationStatus != AuthorizationStatus.authorized &&
          current.authorizationStatus != AuthorizationStatus.provisional) {
        if (!await _askPermissionOnce()) return;
      }
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

  /// Asks for the notification permission at most once per install, and
  /// only after explaining why in French — this runs on every change of
  /// the signed-in user, which used to re-prompt after a refusal.
  Future<bool> _askPermissionOnce() async {
    if (_asking) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionAskedKey) ?? false) return false;
    // At startup (before runApp) there's no screen to explain on yet:
    // the next user refresh after launch asks instead.
    if (Get.overlayContext == null) return false;
    _asking = true;
    try {
      // Right after signup the dashboard is still building its
      // controllers; let it settle before putting a dialog on top.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (Get.isDialogOpen ?? false) return false;
      // The guided tour's spotlight overlay would sit on top of the dialog
      // and swallow its taps: wait — GuidedTourController.finish() asks
      // again once the tour is over or skipped.
      if (Get.isRegistered<GuidedTourController>()) {
        final step = Get.find<GuidedTourController>().step.value;
        if (step != GuidedTourStep.idle && step != GuidedTourStep.done) {
          return false;
        }
      }
      await prefs.setBool(_permissionAskedKey, true);
      final wants = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Reste au courant'),
          content: const Text(
            'Ndeli te prévient quand un allié valide ta preuve, quand une '
            "échéance approche ou quand on t'invite à une quête. Tu pourras "
            'changer ça à tout moment dans les réglages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Plus tard'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Activer'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      if (wants != true) return false;
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } finally {
      _asking = false;
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
    _refreshLocalState(envelope);
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
      final envelope = PushEnvelope.fromData(message.data);
      _open(envelope);
    } catch (_) {
      _openFallback();
    }
  }

  void _refreshLocalState(PushEnvelope envelope) {
    if (Get.isRegistered<NotificationController>()) {
      unawaited(Get.find<NotificationController>().loadNotifications());
    }
    final questId = questIdToRefresh(envelope);
    if (questId != null && Get.isRegistered<QuestListController>()) {
      unawaited(Get.find<QuestListController>().refreshQuest(questId));
    }
    if (!envelope.type.startsWith('ally_') ||
        !Get.isRegistered<AlliesController>()) {
      return;
    }
    final allies = Get.find<AlliesController>();
    unawaited(allies.loadAllyRequests());
    if (envelope.type == 'ally_request_accepted' ||
        envelope.type == 'ally_invite_accepted' ||
        envelope.type == 'ally_removed') {
      unawaited(allies.loadAllies());
    }
  }

  void _open(PushEnvelope envelope) {
    _refreshLocalState(envelope);
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
