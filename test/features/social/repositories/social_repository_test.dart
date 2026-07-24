import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late SocialRepository repository;

  setUp(() {
    mockClient = MockApiClient();
    repository = SocialRepository(mockClient);
  });

  group('SocialRepository.fetchAllies', () {
    test('GETs /allies and returns the parsed list', () async {
      when(() => mockClient.get<dynamic>('/allies')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {'userId': 'u-2', 'firstName': 'Marie', 'lastName': 'Kone', 'avatarUrl': null},
          ],
        ),
      );

      final allies = await repository.fetchAllies();

      expect(allies, hasLength(1));
      expect(allies.single.firstName, 'Marie');
    });

    test('throws SocialException on failure', () async {
      when(() => mockClient.get<dynamic>('/allies')).thenAnswer(
        (_) async => const Response(statusCode: 401, body: {'message': 'Non authentifié'}),
      );

      expect(
        () => repository.fetchAllies(),
        throwsA(isA<SocialException>().having((e) => e.message, 'message', 'Non authentifié')),
      );
    });
  });

  group('SocialRepository.createInvitation', () {
    test('POSTs /allies/invitations and unwraps the {invitation, token, deepLink} envelope',
        () async {
      when(() => mockClient.post<dynamic>('/allies/invitations', any())).thenAnswer(
        (_) async => Response(
          statusCode: 201,
          body: {
            'invitation': {
              'id': 'inv-1',
              'status': 'pending',
              'expiresAt': '2026-01-08T00:00:00.000Z',
            },
            'token': 'tok-abc',
            'deepLink': 'axiom://invite?token=tok-abc',
          },
        ),
      );

      final invitation = await repository.createInvitation();

      expect(invitation.id, 'inv-1');
      expect(invitation.token, 'tok-abc');
      expect(invitation.deepLink, 'axiom://invite?token=tok-abc');
    });

    test('includes inviteeContact in the body when given', () async {
      when(() => mockClient.post<dynamic>('/allies/invitations', any())).thenAnswer(
        (_) async => Response(
          statusCode: 201,
          body: {
            'invitation': {
              'id': 'inv-1',
              'status': 'pending',
              'expiresAt': '2026-01-08T00:00:00.000Z',
            },
            'token': 'tok-abc',
            'deepLink': 'axiom://invite/tok-abc',
          },
        ),
      );

      await repository.createInvitation(inviteeContact: 'friend@example.com');

      final captured = verify(
        () => mockClient.post<dynamic>('/allies/invitations', captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'inviteeContact': 'friend@example.com'});
    });

    test('omits inviteeContact from the body when not given', () async {
      when(() => mockClient.post<dynamic>('/allies/invitations', any())).thenAnswer(
        (_) async => Response(
          statusCode: 201,
          body: {
            'invitation': {
              'id': 'inv-1',
              'status': 'pending',
              'expiresAt': '2026-01-08T00:00:00.000Z',
            },
            'token': 'tok-abc',
            'deepLink': 'axiom://invite/tok-abc',
          },
        ),
      );

      await repository.createInvitation();

      final captured = verify(
        () => mockClient.post<dynamic>('/allies/invitations', captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(captured, isEmpty);
    });
  });

  group('SocialRepository.fetchInvitations', () {
    test('GETs /allies/invitations — persisted rows have no token/deepLink', () async {
      when(() => mockClient.get<dynamic>('/allies/invitations')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {
              'id': 'inv-1',
              'status': 'pending',
              'expiresAt': '2026-01-08T00:00:00.000Z',
            },
          ],
        ),
      );

      final invitations = await repository.fetchInvitations();

      expect(invitations, hasLength(1));
      expect(invitations.single.token, isNull);
      expect(invitations.single.deepLink, isNull);
    });
  });

  group('SocialRepository.redeemInvitation / declineInvitation', () {
    test('redeemInvitation POSTs the token to /allies/invitations/redeem', () async {
      when(() => mockClient.post<dynamic>('/allies/invitations/redeem', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.redeemInvitation('tok-abc');

      final captured =
          verify(() => mockClient.post<dynamic>('/allies/invitations/redeem', captureAny()))
              .captured
              .single as Map;
      expect(captured['token'], 'tok-abc');
    });

    test('declineInvitation POSTs the token to /allies/invitations/decline', () async {
      when(() => mockClient.post<dynamic>('/allies/invitations/decline', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.declineInvitation('tok-abc');

      verify(() => mockClient.post<dynamic>('/allies/invitations/decline', {'token': 'tok-abc'}))
          .called(1);
    });

    test('redeemInvitation throws SocialException on an expired token', () async {
      when(() => mockClient.post<dynamic>('/allies/invitations/redeem', any())).thenAnswer(
        (_) async => const Response(statusCode: 400, body: {'message': 'Invitation expirée'}),
      );

      expect(() => repository.redeemInvitation('tok-abc'), throwsA(isA<SocialException>()));
    });
  });

  group('SocialRepository.searchUsers', () {
    test('GETs /users/search with the query param', () async {
      when(() => mockClient.get<dynamic>('/users/search', query: any(named: 'query'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {'id': 'u-4', 'firstName': 'Awa', 'lastName': 'Traore', 'avatarUrl': null},
          ],
        ),
      );

      final results = await repository.searchUsers('Awa');

      final captured =
          verify(() => mockClient.get<dynamic>('/users/search', query: captureAny(named: 'query')))
              .captured
              .single as Map;
      expect(captured['q'], 'Awa');
      expect(results.single.firstName, 'Awa');
    });
  });

  group('SocialRepository.sendAllyRequest', () {
    test('POSTs the recipientId to /allies/requests', () async {
      when(() => mockClient.post<dynamic>('/allies/requests', any()))
          .thenAnswer((_) async => const Response(statusCode: 201, body: {}));

      await repository.sendAllyRequest('u-4');

      verify(() => mockClient.post<dynamic>('/allies/requests', {'recipientId': 'u-4'}))
          .called(1);
    });

    test('throws SocialException on a duplicate request (409)', () async {
      when(() => mockClient.post<dynamic>('/allies/requests', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 409,
          body: {'message': 'Une demande existe déjà'},
        ),
      );

      expect(() => repository.sendAllyRequest('u-4'), throwsA(isA<SocialException>()));
    });
  });

  group('SocialRepository.fetchAllyRequests', () {
    test('GETs /allies/requests', () async {
      when(() => mockClient.get<dynamic>('/allies/requests')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {
              'id': 'req-1',
              'direction': 'incoming',
              'status': 'pending',
              'otherUser': {
                'id': 'u-4',
                'firstName': 'Awa',
                'lastName': 'Traore',
                'avatarUrl': null,
              },
            },
          ],
        ),
      );

      final requests = await repository.fetchAllyRequests();

      expect(requests, hasLength(1));
      expect(requests.single.direction.name, 'incoming');
    });
  });

  group('SocialRepository.respondToAllyRequest', () {
    test('POSTs the action to /allies/requests/:id/respond', () async {
      when(() => mockClient.post<dynamic>('/allies/requests/req-1/respond', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.respondToAllyRequest('req-1', accept: true);

      verify(() => mockClient
              .post<dynamic>('/allies/requests/req-1/respond', {'action': 'accept'}))
          .called(1);
    });
  });

  group('SocialRepository.fetchValidations', () {
    test('GETs /validations without a status filter', () async {
      when(() => mockClient.get<dynamic>('/validations', query: any(named: 'query')))
          .thenAnswer((_) async => const Response(statusCode: 200, body: []));

      await repository.fetchValidations();

      verify(() => mockClient.get<dynamic>('/validations', query: null)).called(1);
    });

    test('GETs /validations?status=pending when filtered', () async {
      when(() => mockClient.get<dynamic>('/validations', query: any(named: 'query')))
          .thenAnswer((_) async => const Response(statusCode: 200, body: []));

      await repository.fetchValidations(status: 'pending');

      verify(() => mockClient.get<dynamic>('/validations', query: {'status': 'pending'}))
          .called(1);
    });
  });

  group('SocialRepository.decideValidation', () {
    test('POSTs the decision to /validations/:id/decision', () async {
      when(() => mockClient.post<dynamic>('/validations/val-1/decision', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.decideValidation('val-1', approved: true);

      verify(() => mockClient
              .post<dynamic>('/validations/val-1/decision', {'decision': 'approved'}))
          .called(1);
    });
  });
}
