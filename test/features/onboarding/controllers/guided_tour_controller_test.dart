import 'package:axiom/features/auth/models/user_model.dart';
import 'package:axiom/features/onboarding/controllers/guided_tour_controller.dart';
import 'package:axiom/features/onboarding/models/first_quest_template.dart';
import 'package:axiom/features/profile/models/profile_model.dart';
import 'package:axiom/features/profile/repositories/profile_repository.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/social/models/ally_invitation.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

class FakeProfile extends Fake implements Profile {}

User user({DateTime? onboardingCompletedAt}) => User(
  id: 'user-1',
  email: 'awa@example.com',
  firstName: 'Awa',
  lastName: 'Diallo',
  role: 'user',
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
  onboardingCompletedAt: onboardingCompletedAt,
);

QuestModel quest() => QuestModel(
  id: 'q-1',
  title: 'Méditer 10 minutes',
  description: '',
  creatorId: 'user-1',
  frequency: QuestFrequency.daily,
  durationDays: 30,
  targetPerPeriod: 1,
  startDate: DateTime(2026, 11, 7),
  deadline: DateTime(2026, 12, 7),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.low,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: false,
  status: QuestStatus.active,
  progress: 0,
  streakDays: 0,
);

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  late MockQuestRepository questRepository;
  late MockProfileRepository profileRepository;
  late MockSocialRepository socialRepository;
  late QuestListController quests;
  late Rxn<User> currentUser;
  late GuidedTourController tour;

  setUp(() {
    questRepository = MockQuestRepository();
    profileRepository = MockProfileRepository();
    socialRepository = MockSocialRepository();
    quests = QuestListController(questRepository);
    currentUser = Rxn<User>(user());
    when(
      () => profileRepository.updateMe(any()),
    ).thenAnswer((_) async => FakeProfile());
    tour = Get.put(
      GuidedTourController(
        quests: quests,
        profileRepository: profileRepository,
        socialRepository: socialRepository,
        currentUser: currentUser,
      ),
    );
  });

  tearDown(Get.reset);

  group('evaluate', () {
    test('starts at the first-quest bubble for a new user', () async {
      await tour.evaluate();
      expect(tour.step.value, GuidedTourStep.createQuest);
    });

    test('never starts once onboarding was completed', () async {
      currentUser.value = user(onboardingCompletedAt: DateTime(2026, 11, 2));
      await tour.evaluate();
      expect(tour.step.value, GuidedTourStep.idle);
      verifyNever(() => profileRepository.updateMe(any()));
    });

    test(
      'silently completes for an existing user who already has quests',
      () async {
        quests.quests.add(quest());
        await tour.evaluate();

        expect(tour.step.value, GuidedTourStep.done);
        verify(
          () => profileRepository.updateMe({'onboardingCompleted': true}),
        ).called(1);
        expect(currentUser.value!.onboardingCompletedAt, isNotNull);
      },
    );

    test('does nothing without a signed-in user', () async {
      currentUser.value = null;
      await tour.evaluate();
      expect(tour.step.value, GuidedTourStep.idle);
    });

    test('does not restart a tour already in progress', () async {
      await tour.evaluate();
      tour.step.value = GuidedTourStep.checkIn;
      await tour.evaluate();
      expect(tour.step.value, GuidedTourStep.checkIn);
    });
  });

  group('account switch', () {
    test('a different signed-in user starts from a clean tour', () async {
      await tour.evaluate();
      await tour.finish();
      expect(tour.step.value, GuidedTourStep.done);

      currentUser.value = User(
        id: 'user-2',
        email: 'binta@example.com',
        firstName: 'Binta',
        lastName: 'Sow',
        role: 'user',
        createdAt: DateTime(2026, 11, 7),
        updatedAt: DateTime(2026, 11, 7),
      );
      await Future<void>.delayed(Duration.zero);
      expect(tour.step.value, GuidedTourStep.idle);

      await tour.evaluate();
      expect(tour.step.value, GuidedTourStep.createQuest);
    });

    test('a refresh of the same user keeps the tour where it is', () async {
      await tour.evaluate();
      currentUser.value = currentUser.value!.copyWith();
      await Future<void>.delayed(Duration.zero);
      expect(tour.step.value, GuidedTourStep.createQuest);
    });
  });

  group('launchTemplate', () {
    test('creates the template quest and moves to the launch screen', () async {
      when(
        () => questRepository.createQuest(
          any(),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => quest());
      await tour.evaluate();

      final created = await tour.launchTemplate(firstQuestTemplates.first);

      expect(created?.id, 'q-1');
      expect(tour.launchedQuest.value?.id, 'q-1');
      expect(tour.step.value, GuidedTourStep.launched);
      final payload =
          verify(
                () => questRepository.createQuest(
                  captureAny(),
                  idempotencyKey: any(named: 'idempotencyKey'),
                ),
              ).captured.single
              as Map;
      expect(payload['title'], firstQuestTemplates.first.title);
    });

    test('retries reuse the same idempotency key', () async {
      var calls = 0;
      when(
        () => questRepository.createQuest(
          any(),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {
        if (calls++ == 0) throw QuestException('Réseau indisponible');
        return quest();
      });
      await tour.evaluate();

      expect(await tour.launchTemplate(firstQuestTemplates.first), isNull);
      expect(tour.step.value, GuidedTourStep.createQuest);
      expect(tour.errorMessage.value, 'Réseau indisponible');
      await tour.launchTemplate(firstQuestTemplates.first);

      final keys = verify(
        () => questRepository.createQuest(
          any(),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(keys.toSet(), hasLength(1));
    });
  });

  group('custom quest', () {
    test(
      'a quest created from the full wizard skips to the check-in bubble',
      () async {
        await tour.evaluate();
        quests.quests.add(quest());
        await Future<void>.delayed(Duration.zero);

        expect(tour.step.value, GuidedTourStep.checkIn);
      },
    );
  });

  group('invite', () {
    test('builds a share message around a fresh invite link', () async {
      when(() => socialRepository.createInvitation()).thenAnswer(
        (_) async => AllyInvitation(
          id: 'inv-1',
          status: InvitationStatus.pending,
          expiresAt: DateTime(2026, 11, 14),
          deepLink: 'https://ndeli.app/invite/abc',
        ),
      );
      tour.launchedQuest.value = quest();

      final message = await tour.prepareInviteMessage();

      expect(message, contains('https://ndeli.app/invite/abc'));
      expect(message, contains('Méditer 10 minutes'));
      expect(tour.inviteShared.value, isFalse);
    });

    test('returns null and surfaces the error when the link fails', () async {
      when(
        () => socialRepository.createInvitation(),
      ).thenThrow(SocialException('Impossible de créer le lien'));

      expect(await tour.prepareInviteMessage(), isNull);
      expect(tour.errorMessage.value, 'Impossible de créer le lien');
    });
  });

  group('finish', () {
    test('persists completion once, even if called twice', () async {
      await tour.evaluate();
      await tour.finish();
      await tour.finish();

      expect(tour.step.value, GuidedTourStep.done);
      verify(
        () => profileRepository.updateMe({'onboardingCompleted': true}),
      ).called(1);
    });

    test('still ends the tour locally when the backend call fails', () async {
      when(
        () => profileRepository.updateMe(any()),
      ).thenThrow(ProfileException('Hors ligne'));
      await tour.evaluate();

      await tour.finish();

      expect(tour.step.value, GuidedTourStep.done);
    });
  });
}
