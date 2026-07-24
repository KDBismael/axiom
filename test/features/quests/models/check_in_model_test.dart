import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';

void main() {
  group('CheckIn.fromJson', () {
    test('parses the check-in shape with no evidence', () {
      final checkIn = CheckIn.fromJson({
        'id': 'ci-1',
        'questId': 'q-1',
        'date': '2026-01-05T00:00:00.000Z',
      });

      expect(checkIn.id, 'ci-1');
      expect(checkIn.questId, 'q-1');
      expect(checkIn.date, DateTime.parse('2026-01-05T00:00:00.000Z'));
      expect(checkIn.evidence, isEmpty);
    });

    test('parses the check-in with its evidence list', () {
      final checkIn = CheckIn.fromJson({
        'id': 'ci-1',
        'questId': 'q-1',
        'date': '2026-01-05T00:00:00.000Z',
        'evidence': [
          {
            'id': 'ev-1',
            'proofType': 'photo',
            'fileId': 'f-1',
            'textContent': null,
            'description': null,
            'status': 'rejected',
          },
          {
            'id': 'ev-2',
            'proofType': 'photo',
            'fileId': 'f-2',
            'textContent': null,
            'description': null,
            'status': 'pending',
          },
        ],
      });

      expect(checkIn.evidence, hasLength(2));
      expect(checkIn.evidence.last.status, EvidenceStatus.pending);
    });
  });

  group('Evidence.fromJson', () {
    test('parses a photo proof', () {
      final evidence = Evidence.fromJson({
        'id': 'ev-1',
        'proofType': 'photo',
        'fileId': 'f-1',
        'textContent': null,
        'description': 'Salle de sport',
        'status': 'pending',
      });

      expect(evidence.id, 'ev-1');
      expect(evidence.proofType, ProofType.photo);
      expect(evidence.fileId, 'f-1');
      expect(evidence.textContent, isNull);
      expect(evidence.description, 'Salle de sport');
      expect(evidence.status, EvidenceStatus.pending);
    });

    test('parses a text proof with approved status', () {
      final evidence = Evidence.fromJson({
        'id': 'ev-2',
        'proofType': 'text',
        'fileId': null,
        'textContent': "J'ai couru 5km",
        'description': null,
        'status': 'approved',
      });

      expect(evidence.proofType, ProofType.text);
      expect(evidence.textContent, "J'ai couru 5km");
      expect(evidence.status, EvidenceStatus.approved);
    });

    test('parses a rejected proof', () {
      final evidence = Evidence.fromJson({
        'id': 'ev-3',
        'proofType': 'video',
        'fileId': 'f-2',
        'textContent': null,
        'description': null,
        'status': 'rejected',
      });

      expect(evidence.proofType, ProofType.video);
      expect(evidence.status, EvidenceStatus.rejected);
    });
  });

  group('CheckInResult.fromJson', () {
    test('parses the check-in response envelope including evidence', () {
      final result = CheckInResult.fromJson({
        'id': 'ci-1',
        'questId': 'q-1',
        'date': '2026-01-05T00:00:00.000Z',
        'streakDays': 4,
        'progress': 0.5,
        'currentPeriodCount': 1,
        'targetPerPeriod': 1,
        'evidence': {
          'id': 'ev-1',
          'proofType': 'photo',
          'fileId': 'f-1',
          'textContent': null,
          'description': null,
          'status': 'pending',
        },
      });

      expect(result.checkIn.id, 'ci-1');
      expect(result.streakDays, 4);
      expect(result.progress, 0.5);
      expect(result.evidence, isNotNull);
      expect(result.evidence!.id, 'ev-1');
      expect(result.checkIn.evidence.single.id, 'ev-1');
    });

    test('evidence is null when no proof was attached', () {
      final result = CheckInResult.fromJson({
        'id': 'ci-2',
        'questId': 'q-1',
        'date': '2026-01-06T00:00:00.000Z',
        'streakDays': 5,
        'progress': 0.55,
        'currentPeriodCount': 1,
        'targetPerPeriod': 1,
        'evidence': null,
      });

      expect(result.evidence, isNull);
      expect(result.checkIn.evidence, isEmpty);
    });
  });
}
