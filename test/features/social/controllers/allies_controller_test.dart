import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/social/controllers/allies_controller.dart';
import 'package:axiom/features/social/models/ally.dart';
import 'package:axiom/features/social/models/ally_invitation.dart';
import 'package:axiom/features/social/models/ally_request.dart';
import 'package:axiom/features/social/models/user_search_result.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late AlliesController controller;

  setUp(() {
    mockRepository = MockSocialRepository();
    controller = AlliesController(mockRepository);
  });

  group('AlliesController.loadAllies', () {
    test('populates allies on success', () async {
      when(() => mockRepository.fetchAllies()).thenAnswer(
        (_) async => [const Ally(id: 'u-2', firstName: 'Marie', lastName: 'Kone')],
      );

      await controller.loadAllies();

      expect(controller.allies, hasLength(1));
    });
  });

  group('AlliesController.createInvitation', () {
    test('stores the created invitation', () async {
      final invitation = AllyInvitation(
        id: 'inv-1',
        token: 'tok-abc',
        deepLink: 'axiom://invite?token=tok-abc',
        status: InvitationStatus.pending,
        expiresAt: DateTime(2026, 1, 8),
      );
      when(() => mockRepository.createInvitation(inviteeContact: any(named: 'inviteeContact')))
          .thenAnswer((_) async => invitation);

      await controller.createInvitation();

      expect(controller.lastCreatedInvitation.value, invitation);
    });

    test('passes the email through to the repository', () async {
      final invitation = AllyInvitation(
        id: 'inv-1',
        status: InvitationStatus.pending,
        expiresAt: DateTime(2026, 1, 8),
      );
      when(() => mockRepository.createInvitation(inviteeContact: any(named: 'inviteeContact')))
          .thenAnswer((_) async => invitation);

      await controller.createInvitation(inviteeContact: 'friend@example.com');

      verify(() => mockRepository.createInvitation(inviteeContact: 'friend@example.com'))
          .called(1);
    });

    test('surfaces the backend French message on failure', () async {
      when(() => mockRepository.createInvitation(inviteeContact: any(named: 'inviteeContact')))
          .thenThrow(SocialException('Erreur serveur'));

      await controller.createInvitation();

      expect(controller.errorMessage.value, 'Erreur serveur');
    });
  });

  group('AlliesController.search', () {
    test('does not call the repository below 2 characters', () async {
      await controller.search('a');
      verifyNever(() => mockRepository.searchUsers(any()));
      expect(controller.searchResults, isEmpty);
    });

    test('searches once the query reaches 2 characters', () async {
      when(() => mockRepository.searchUsers('Aw')).thenAnswer(
        (_) async => [const UserSearchResult(id: 'u-4', firstName: 'Awa', lastName: 'Traore')],
      );

      await controller.search('Aw');

      expect(controller.searchResults, hasLength(1));
    });
  });

  group('AlliesController.sendRequest', () {
    test('surfaces the duplicate-request 409 French message', () async {
      when(() => mockRepository.sendAllyRequest('u-4'))
          .thenThrow(SocialException('Une demande existe déjà'));

      await controller.sendRequest('u-4');

      expect(controller.errorMessage.value, 'Une demande existe déjà');
    });
  });

  group('AlliesController.respondToRequest', () {
    test('reloads ally requests after responding', () async {
      when(() => mockRepository.respondToAllyRequest('req-1', accept: true))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchAllyRequests()).thenAnswer((_) async => [
            AllyRequest(
              id: 'req-2',
              direction: AllyRequestDirection.incoming,
              status: AllyRequestStatus.pending,
              otherUser: const AllyRequestUser(id: 'u-5', firstName: 'X', lastName: 'Y'),
            ),
          ]);
      when(() => mockRepository.fetchAllies()).thenAnswer((_) async => []);

      await controller.respondToRequest('req-1', accept: true);

      verify(() => mockRepository.respondToAllyRequest('req-1', accept: true)).called(1);
      expect(controller.allyRequests, hasLength(1));
    });
  });
}
