import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/routes/app_pages.dart';
import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/core/services/pending_invite_service.dart';
import 'package:axiom/features/notifications/services/notification_navigation_service.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/features/quests/models/quest_result.dart';
import 'package:axiom/features/quests/controllers/quest_result_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/notifications/models/notification_model.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockRepository extends Mock implements QuestRepository {}

final resultJson = <String, dynamic>{
  'id': 'r',
  'questId': 'q',
  'title': 'Lire',
  'ownerId': 'owner',
  'ownerFirstName': 'Aminata',
  'ownerLastName': 'Test',
  'ownerAvatarUrl': null,
  'status': 'completed',
  'reason': 'deadline',
  'resolvedAt': '2026-11-11T12:00:00Z',
  'frequency': 'daily',
  'successThresholdPercent': 66,
  'completedPeriods': 2,
  'expectedPeriods': 3,
  'completionPercent': 66.7,
};

void main() {
  test(
    'a result redirect survives login and its route works without Home dependencies',
    () async {
      Get.testMode = true;
      try {
        final pending = PendingInviteService();
        pending.stashRedirect(
          notificationTarget('quest_completed', {
            'questId': 'q',
            'resultId': 'r',
          }),
        );
        final target = pending.consumeRedirectTarget();
        expect(target, (route: AppRoutes.questResult, arguments: 'q'));
        expect(pending.consumeRedirectTarget().route, AppRoutes.home);
        Get.put<ApiClient>(ApiClient(tokenStorage: TokenStorage()));
        AppPages.pages
            .firstWhere((p) => p.name == target.route)
            .binding!
            .dependencies();
        expect(Get.isRegistered<QuestRepository>(), isTrue);
        expect(Get.isRegistered<QuestResultController>(), isTrue);
        expect(Get.find<QuestRepository>(), isA<QuestRepository>());
      } finally {
        Get.reset();
      }
    },
  );
  test('parses the authoritative snapshot and formats French percentages', () {
    final result = QuestResult.fromJson(resultJson);
    expect(result.ownerName, 'Aminata Test');
    expect(result.isSuccess, isTrue);
    expect(result.percentageLabel, '66,7 %');
    expect(result.periodsLabel, '2 / 3 jours');
    expect(
      QuestResult.fromJson({
        ...resultJson,
        'completionPercent': 85,
      }).percentageLabel,
      '85 %',
    );
    expect(
      QuestResult.fromJson({...resultJson, 'frequency': 'weekly'}).periodsLabel,
      '2 / 3 semaines',
    );
    expect(
      QuestResult.fromJson({
        ...resultJson,
        'status': 'failed',
        'reason': 'deletion_rejected',
      }).isDeletionRejection,
      isTrue,
    );
  });
  test(
    'fetches only the authorized result endpoint and treats 404 as unavailable',
    () async {
      final client = MockApiClient();
      final repository = QuestRepository(client);
      when(
        () => client.get<dynamic>('/quests/q/result'),
      ).thenAnswer((_) async => Response(statusCode: 200, body: resultJson));
      expect((await repository.fetchResult('q'))?.id, 'r');
      when(
        () => client.get<dynamic>('/quests/q/result'),
      ).thenAnswer((_) async => const Response(statusCode: 404));
      expect(await repository.fetchResult('q'), isNull);
      when(() => client.get<dynamic>('/quests/q/result')).thenAnswer(
        (_) async => const Response(
          statusCode: 500,
          body: {'message': 'Erreur temporaire'},
        ),
      );
      await expectLater(
        repository.fetchResult('q'),
        throwsA(isA<QuestException>()),
      );
    },
  );
  test(
    'controller exposes loading, failure, retry and unavailable states',
    () async {
      final repository = MockRepository();
      final controller = QuestResultController(repository, 'q');
      when(() => repository.fetchResult('q')).thenAnswer((_) async {
        expect(controller.isLoading.value, isTrue);
        throw QuestException('Erreur temporaire');
      });
      await controller.load();
      expect(controller.errorMessage.value, 'Erreur temporaire');
      expect(controller.isLoading.value, isFalse);
      when(
        () => repository.fetchResult('q'),
      ).thenAnswer((_) async => QuestResult.fromJson(resultJson));
      await controller.load();
      expect(controller.result.value?.id, 'r');
      expect(controller.errorMessage.value, isNull);
      when(() => repository.fetchResult('q')).thenAnswer((_) async => null);
      await controller.load();
      expect(controller.isUnavailable, isTrue);
      expect(controller.result.value, isNull);
    },
  );
  test(
    'result notification copy contains owner, outcome, quest and percentage',
    () {
      final notification = AppNotification(
        id: 'n',
        type: 'quest_failed',
        payload: {
          'resultId': 'r',
          'title': 'Lire',
          'firstName': 'Aminata',
          'completionPercent': 66.7,
        },
        createdAt: DateTime(2026),
      );
      expect(
        notification.resultSummary,
        'Aminata a échoué à « Lire » — 66,7 %.',
      );
      expect(
        AppNotification(
          id: 'old',
          type: 'quest_completed',
          payload: const {},
          createdAt: DateTime(2026),
        ).resultSummary,
        isNull,
      );
    },
  );
}
