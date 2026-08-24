import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:live_activities/live_activities.dart';

/// Keeps the running focus session visible outside the app — an iOS Live
/// Activity (lock screen / Dynamic Island) or an Android ongoing
/// foreground-service notification. This is the single seam
/// `FocusTimerController` talks to; swapping the underlying plugin or
/// platform mechanism later only touches this file.
///
/// Deliberately display-only for this pass: neither platform's presence
/// surface exposes interactive pause/finish controls — all control still
/// happens from `quest_focus_timer_view.dart` inside the app.
abstract class FocusPresenceService {
  Future<void> start({required String questTitle, required DateTime startedAt});
  Future<void> pause();
  Future<void> resume();
  Future<void> finish();
}

/// Default implementation, dispatching to the iOS/Android plugins. A
/// failure on either platform (activity not supported on this OS version,
/// permission denied, etc.) never blocks the timer itself — every call is
/// wrapped defensively.
class DefaultFocusPresenceService implements FocusPresenceService {
  DefaultFocusPresenceService({LiveActivities? liveActivities})
    : _liveActivities = liveActivities ?? LiveActivities();

  final LiveActivities _liveActivities;
  String? _activityId;
  String? _questTitle;
  bool _iosInitialized = false;

  static const _androidChannelId = 'focus_timer_service';

  // Must match the App Group configured in both the Runner and
  // FocusTimerActivity targets' entitlements (Xcode > Signing & Capabilities
  // > App Groups) — the live_activities plugin uses it to bridge data to the
  // widget extension and won't create an activity without a prior init().
  static const _iosAppGroupId = 'group.com.axiom.deli.focustimer';

  @override
  Future<void> start({
    required String questTitle,
    required DateTime startedAt,
  }) async {
    _questTitle = questTitle;
    if (Platform.isIOS) {
      await _startIOS(questTitle: questTitle, startedAt: startedAt);
    } else if (Platform.isAndroid) {
      await _startAndroid(questTitle: questTitle);
    }
  }

  Future<void> _startIOS({
    required String questTitle,
    required DateTime startedAt,
  }) async {
    final id = 'focus-${startedAt.millisecondsSinceEpoch}';
    try {
      if (!_iosInitialized) {
        await _liveActivities.init(appGroupId: _iosAppGroupId);
        _iosInitialized = true;
      }
      await _liveActivities.createActivity(id, {
        'questTitle': questTitle,
        'startedAt': startedAt.millisecondsSinceEpoch.toString(),
        'paused': 'false',
      });
      _activityId = id;
    } catch (e) {
      debugPrint('FocusPresenceService.start (iOS) failed: $e');
    }
  }

  Future<void> _startAndroid({required String questTitle}) async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: _androidChannelId,
          channelName: 'Minuteur de focus',
          channelDescription:
              'Affiche votre session de focus en cours, même hors de l’app.',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          allowWakeLock: true,
        ),
      );
      await FlutterForegroundTask.startService(
        notificationTitle: questTitle,
        notificationText: 'Session de focus en cours…',
      );
    } catch (e) {
      debugPrint('FocusPresenceService.start (Android) failed: $e');
    }
  }

  @override
  Future<void> pause() => _update(paused: true);

  @override
  Future<void> resume() => _update(paused: false);

  Future<void> _update({required bool paused}) async {
    if (Platform.isIOS) {
      if (_activityId == null) return;
      try {
        await _liveActivities.updateActivity(_activityId!, {
          'paused': paused.toString(),
        });
      } catch (e) {
        debugPrint('FocusPresenceService.update (iOS) failed: $e');
      }
    } else if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.updateService(
          notificationTitle: _questTitle ?? '',
          notificationText: paused
              ? 'En pause'
              : 'Session de focus en cours…',
        );
      } catch (e) {
        debugPrint('FocusPresenceService.update (Android) failed: $e');
      }
    }
  }

  @override
  Future<void> finish() async {
    if (Platform.isIOS) {
      if (_activityId == null) return;
      try {
        await _liveActivities.endActivity(_activityId!);
      } catch (e) {
        debugPrint('FocusPresenceService.finish (iOS) failed: $e');
      } finally {
        _activityId = null;
      }
    } else if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.stopService();
      } catch (e) {
        debugPrint('FocusPresenceService.finish (Android) failed: $e');
      }
    }
  }
}
