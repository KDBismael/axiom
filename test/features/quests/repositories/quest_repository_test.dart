import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/services/evidence_picker_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late QuestRepository repository;

  final questJson = {
    'id': 'q-1',
    'title': 'Gym 3x par semaine',
    'description': 'Ne jamais sauter une séance.',
    'frequency': 'weekly',
    'durationDays': 30,
    'targetPerPeriod': 1,
    'startDate': '2026-01-01T00:00:00.000Z',
    'deadline': '2026-02-01T00:00:00.000Z',
    'gracePeriodDays': 2,
    'riskLevel': 'medium',
    'requiresProof': true,
    'successThresholdPercent': 80,
    'hasStake': false,
    'stakeAmountXof': null,
    'fundsDistribution': null,
    'status': 'active',
    'progress': 0.0,
    'streakDays': 0,
  };

  setUp(() {
    mockClient = MockApiClient();
    repository = QuestRepository(mockClient);
  });

  group('QuestRepository.fetchQuests', () {
    test('GETs /quests and returns the parsed list', () async {
      when(() => mockClient.get<dynamic>('/quests'))
          .thenAnswer((_) async => Response(statusCode: 200, body: [questJson]));

      final quests = await repository.fetchQuests();

      expect(quests, hasLength(1));
      expect(quests.single.id, 'q-1');
    });

    test('throws QuestException on failure', () async {
      when(() => mockClient.get<dynamic>('/quests')).thenAnswer(
        (_) async => const Response(statusCode: 401, body: {'message': 'Non authentifié'}),
      );

      expect(
        () => repository.fetchQuests(),
        throwsA(isA<QuestException>().having((e) => e.message, 'message', 'Non authentifié')),
      );
    });
  });

  group('QuestRepository.fetchQuest', () {
    test('GETs /quests/:id', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1'))
          .thenAnswer((_) async => Response(statusCode: 200, body: questJson));

      final quest = await repository.fetchQuest('q-1');

      expect(quest.id, 'q-1');
    });
  });

  group('QuestRepository.createQuest', () {
    test('POSTs the payload to /quests and returns the created quest', () async {
      when(() => mockClient.post<dynamic>('/quests', any()))
          .thenAnswer((_) async => Response(statusCode: 201, body: questJson));

      final quest = await repository.createQuest({'title': 'Gym 3x par semaine'});

      final captured = verify(() => mockClient.post<dynamic>('/quests', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['title'], 'Gym 3x par semaine');
      expect(quest.id, 'q-1');
    });

    test('joins list-shaped validation errors with newlines', () async {
      when(() => mockClient.post<dynamic>('/quests', any())).thenAnswer(
        (_) async => Response(
          statusCode: 400,
          body: {
            'message': ['title should not be empty'],
          },
        ),
      );

      expect(
        () => repository.createQuest({}),
        throwsA(
          isA<QuestException>().having((e) => e.message, 'message', 'title should not be empty'),
        ),
      );
    });
  });

  group('QuestRepository.updateQuest', () {
    test('PATCHes /quests/:id with the given changes', () async {
      when(() => mockClient.patch<dynamic>('/quests/q-1', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: questJson));

      await repository.updateQuest('q-1', {'description': 'Updated'});

      final captured = verify(() => mockClient.patch<dynamic>('/quests/q-1', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured, {'description': 'Updated'});
    });

    test('surfaces the "frozen field" French message on failure', () async {
      when(() => mockClient.patch<dynamic>('/quests/q-1', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 400,
          body: {'message': 'Ce champ ne peut plus être modifié'},
        ),
      );

      expect(
        () => repository.updateQuest('q-1', {'frequency': 'daily'}),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.requestDeletion', () {
    test('deletes immediately when the backend returns deleted: true', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/delete-request', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 200,
          body: {'deleted': true, 'pending': false},
        ),
      );

      final outcome = await repository.requestDeletion('q-1');

      expect(outcome.deleted, isTrue);
      expect(outcome.pending, isFalse);
    });

    test('reports a cancelled+refunded outcome', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/delete-request', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 200,
          body: {'deleted': false, 'pending': false, 'cancelled': true},
        ),
      );

      final outcome = await repository.requestDeletion('q-1');

      expect(outcome.deleted, isFalse);
      expect(outcome.cancelled, isTrue);
    });

    test('reports a pending outcome with the initial vote tally', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/delete-request', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 202,
          body: {
            'deleted': false,
            'pending': true,
            'requestId': 'req-1',
            'votes': {'approved': 0, 'total': 2},
          },
        ),
      );

      final outcome = await repository.requestDeletion('q-1');

      expect(outcome.pending, isTrue);
      expect(outcome.requestId, 'req-1');
      expect(outcome.votes!.total, 2);
    });

    test('throws QuestException when the caller is not the owner', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/delete-request', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 403,
          body: {'message': 'Seul le propriétaire peut demander la suppression'},
        ),
      );

      expect(() => repository.requestDeletion('q-1'), throwsA(isA<QuestException>()));
    });
  });

  group('QuestRepository.fetchDeletionRequest', () {
    test('GETs /quests/:id/delete-request and returns the tally', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1/delete-request')).thenAnswer(
        (_) async => const Response(
          statusCode: 200,
          body: {
            'id': 'req-1',
            'status': 'pending',
            'votes': {'approved': 1, 'total': 2},
          },
        ),
      );

      final request = await repository.fetchDeletionRequest('q-1');

      expect(request!.id, 'req-1');
      expect(request.votes.approved, 1);
    });

    test('returns null when there is no request', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1/delete-request'))
          .thenAnswer((_) async => const Response(statusCode: 200, body: null));

      final request = await repository.fetchDeletionRequest('q-1');

      expect(request, isNull);
    });
  });

  group('QuestRepository.voteOnDeletionRequest', () {
    test('POSTs the approve decision', () async {
      when(() => mockClient.post<dynamic>(
            '/quests/q-1/delete-request/req-1/votes',
            any(),
          )).thenAnswer((_) async => const Response(statusCode: 200, body: {'status': 'approved'}));

      await repository.voteOnDeletionRequest('q-1', 'req-1', approve: true);

      final captured = verify(() => mockClient.post<dynamic>(
            '/quests/q-1/delete-request/req-1/votes',
            captureAny(),
          )).captured.single as Map<String, dynamic>;
      expect(captured, {'decision': 'approve'});
    });

    test('POSTs the reject decision', () async {
      when(() => mockClient.post<dynamic>(
            '/quests/q-1/delete-request/req-1/votes',
            any(),
          )).thenAnswer((_) async => const Response(statusCode: 200, body: {'status': 'rejected'}));

      await repository.voteOnDeletionRequest('q-1', 'req-1', approve: false);

      final captured = verify(() => mockClient.post<dynamic>(
            '/quests/q-1/delete-request/req-1/votes',
            captureAny(),
          )).captured.single as Map<String, dynamic>;
      expect(captured, {'decision': 'reject'});
    });

    test('throws QuestException on a duplicate vote (409)', () async {
      when(() => mockClient.post<dynamic>(
            '/quests/q-1/delete-request/req-1/votes',
            any(),
          )).thenAnswer(
        (_) async => const Response(
          statusCode: 409,
          body: {'message': 'Vous avez déjà voté sur cette demande'},
        ),
      );

      expect(
        () => repository.voteOnDeletionRequest('q-1', 'req-1', approve: true),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.inviteAllies', () {
    test('POSTs the ally ids to /quests/:id/allies', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/allies', any()))
          .thenAnswer((_) async => const Response(statusCode: 201, body: []));

      await repository.inviteAllies('q-1', ['ally-1', 'ally-2']);

      final captured = verify(() => mockClient.post<dynamic>('/quests/q-1/allies', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured, {
        'allyUserIds': ['ally-1', 'ally-2'],
      });
    });

    test('throws QuestException when an ally is already invited (409)', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/allies', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 409,
          body: {'message': 'Un ou plusieurs alliés ont déjà été invités sur cette quête'},
        ),
      );

      expect(
        () => repository.inviteAllies('q-1', ['ally-1']),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.fetchMyAllyInvitations', () {
    test('GETs /quests/ally-invitations and returns the parsed list', () async {
      when(() => mockClient.get<dynamic>('/quests/ally-invitations')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {
              'questId': 'q-1',
              'questTitle': 'Courir tous les jours',
              'invitedAt': '2026-07-01T00:00:00.000Z',
            },
          ],
        ),
      );

      final invitations = await repository.fetchMyAllyInvitations();

      expect(invitations, hasLength(1));
      expect(invitations.single.questId, 'q-1');
      expect(invitations.single.questTitle, 'Courir tous les jours');
    });

    test('throws QuestException on failure', () async {
      when(() => mockClient.get<dynamic>('/quests/ally-invitations')).thenAnswer(
        (_) async => const Response(statusCode: 401, body: {'message': 'Non authentifié'}),
      );

      expect(
        () => repository.fetchMyAllyInvitations(),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.fetchAllyInvitation', () {
    test('GETs /quests/:id/ally-invitation and returns the full terms', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1/ally-invitation')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: {
            'invitation': {'status': 'pending'},
            'quest': {
              'id': 'q-1',
              'title': 'Courir tous les jours',
              'description': '30 minutes de course',
              'frequency': 'daily',
              'durationDays': 30,
              'startDate': '2026-01-01T00:00:00.000Z',
              'deadline': '2026-01-31T00:00:00.000Z',
              'hasStake': true,
              'stakeAmountXof': '5000',
              'fundsDistribution': 'allies',
            },
          },
        ),
      );

      final invitation = await repository.fetchAllyInvitation('q-1');

      expect(invitation.title, 'Courir tous les jours');
      expect(invitation.stakeAmountXof, 5000.0);
    });
  });

  group('QuestRepository.respondToAllyInvitation', () {
    test('POSTs the accept decision', () async {
      when(() => mockClient.post<dynamic>(
            '/quests/q-1/ally-invitation/respond',
            any(),
          )).thenAnswer((_) async => const Response(statusCode: 200, body: {'status': 'accepted'}));

      await repository.respondToAllyInvitation('q-1', accept: true);

      final captured = verify(() => mockClient.post<dynamic>(
            '/quests/q-1/ally-invitation/respond',
            captureAny(),
          )).captured.single as Map<String, dynamic>;
      expect(captured, {'decision': 'accept'});
    });

    test('throws QuestException when already answered', () async {
      when(() => mockClient.post<dynamic>(
            '/quests/q-1/ally-invitation/respond',
            any(),
          )).thenAnswer(
        (_) async => const Response(
          statusCode: 400,
          body: {'message': 'Cette invitation a déjà été traitée'},
        ),
      );

      expect(
        () => repository.respondToAllyInvitation('q-1', accept: false),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.checkIn', () {
    final checkInResultJson = {
      'id': 'ci-1',
      'questId': 'q-1',
      'date': '2026-01-05T00:00:00.000Z',
      'streakDays': 1,
      'progress': 0.1,
      'currentPeriodCount': 1,
      'targetPerPeriod': 1,
      'evidence': null,
    };

    test('POSTs to /quests/:id/check-ins with the proof fields', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/check-ins', any()))
          .thenAnswer((_) async => Response(statusCode: 201, body: checkInResultJson));

      final result = await repository.checkIn(
        'q-1',
        proofType: ProofType.text,
        textContent: 'Fait !',
      );

      final captured =
          verify(() => mockClient.post<dynamic>('/quests/q-1/check-ins', captureAny()))
              .captured
              .single as Map<String, dynamic>;
      expect(captured['proofType'], 'text');
      expect(captured['textContent'], 'Fait !');
      expect(result.streakDays, 1);
    });

    test('throws QuestException with the dedup 409 message', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/check-ins', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 409,
          body: {'message': "Vous avez déjà validé aujourd'hui"},
        ),
      );

      expect(
        () => repository.checkIn('q-1'),
        throwsA(
          isA<QuestException>().having(
            (e) => e.message,
            'message',
            "Vous avez déjà validé aujourd'hui",
          ),
        ),
      );
    });

    test('throws QuestException with the no-ally 400 message', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/check-ins', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 400,
          body: {'message': 'Un allié accepté est requis pour soumettre une preuve'},
        ),
      );

      expect(() => repository.checkIn('q-1', proofType: ProofType.photo, fileId: 'f-1'),
          throwsA(isA<QuestException>()));
    });
  });

  group('QuestRepository.fetchCheckIns', () {
    test('GETs /quests/:id/check-ins', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1/check-ins')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {'id': 'ci-1', 'questId': 'q-1', 'date': '2026-01-05T00:00:00.000Z'},
          ],
        ),
      );

      final checkIns = await repository.fetchCheckIns('q-1');

      expect(checkIns, hasLength(1));
    });
  });

  group('QuestRepository.resubmitProof', () {
    test('POSTs to /quests/:questId/check-ins/:checkInId/proofs', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/check-ins/ci-1/proofs', any())).thenAnswer(
        (_) async => Response(
          statusCode: 201,
          body: {
            'id': 'ev-2',
            'proofType': 'photo',
            'fileId': 'f-2',
            'textContent': null,
            'description': null,
            'status': 'pending',
          },
        ),
      );

      final evidence = await repository.resubmitProof(
        'q-1',
        'ci-1',
        proofType: ProofType.photo,
        fileId: 'f-2',
      );

      expect(evidence.id, 'ev-2');
    });

    test('throws QuestException when a proof is already pending', () async {
      when(() => mockClient.post<dynamic>('/quests/q-1/check-ins/ci-1/proofs', any())).thenAnswer(
        (_) async => const Response(
          statusCode: 400,
          body: {'message': 'Une preuve est déjà en cours de validation'},
        ),
      );

      expect(
        () => repository.resubmitProof('q-1', 'ci-1', proofType: ProofType.text, textContent: 'x'),
        throwsA(isA<QuestException>()),
      );
    });
  });

  group('QuestRepository.fetchEvidence', () {
    test('GETs /quests/:id/evidence', () async {
      when(() => mockClient.get<dynamic>('/quests/q-1/evidence')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: [
            {
              'id': 'ev-1',
              'proofType': 'photo',
              'fileId': 'f-1',
              'textContent': null,
              'description': null,
              'status': 'pending',
            },
          ],
        ),
      );

      final evidence = await repository.fetchEvidence('q-1');

      expect(evidence, hasLength(1));
    });
  });

  group('QuestRepository.uploadEvidenceFile', () {
    test('posts multipart form data to /files/upload and returns the file id', () async {
      final picked = PickedEvidence(
        bytes: Uint8List.fromList([1, 2, 3]),
        sizeBytes: 3,
        filename: 'proof.png',
        mimeType: 'image/png',
      );
      when(() => mockClient.post<dynamic>('/files/upload', any()))
          .thenAnswer((_) async => Response(statusCode: 201, body: {'id': 'f-9'}));

      final id = await repository.uploadEvidenceFile(picked);

      expect(id, 'f-9');
      final captured = verify(() => mockClient.post<dynamic>('/files/upload', captureAny()))
          .captured
          .single as FormData;
      expect(captured.fields.single.key, 'purpose');
      expect(captured.fields.single.value, 'quest_evidence');
      expect(captured.files.single.value.filename, 'proof.png');
    });
  });
}
