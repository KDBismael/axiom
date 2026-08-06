import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/social/models/ally_validation_request.dart';

void main() {
  group('AllyValidationRequest.fromJson', () {
    test('parses a pending photo validation', () {
      final request = AllyValidationRequest.fromJson({
        'id': 'val-1',
        'evidenceId': 'ev-1',
        'status': 'pending',
        'evidence': {
          'id': 'ev-1',
          'questId': 'q-1',
          'proofType': 'photo',
          'textContent': null,
          'fileId': 'f-1',
          'quest': {'title': 'Gym 3x par semaine'},
        },
      });

      expect(request.id, 'val-1');
      expect(request.questId, 'q-1');
      expect(request.questTitle, 'Gym 3x par semaine');
      expect(request.evidenceId, 'ev-1');
      expect(request.proofType, ProofType.photo);
      expect(request.fileId, 'f-1');
      expect(request.status, ValidationDecisionStatus.pending);
    });

    test('parses a cancelled text validation (another ally already decided)', () {
      final request = AllyValidationRequest.fromJson({
        'id': 'val-2',
        'evidenceId': 'ev-2',
        'status': 'cancelled',
        'evidence': {
          'id': 'ev-2',
          'questId': 'q-1',
          'proofType': 'text',
          'textContent': "J'ai lu 20 minutes",
          'fileId': null,
          'quest': {'title': 'Lire 20 minutes'},
        },
      });

      expect(request.proofType, ProofType.text);
      expect(request.textContent, "J'ai lu 20 minutes");
      expect(request.status, ValidationDecisionStatus.cancelled);
    });

    test('parses both the submitter comment and the decision comment', () {
      final request = AllyValidationRequest.fromJson({
        'id': 'val-3',
        'evidenceId': 'ev-3',
        'status': 'approved',
        'comment': 'Bien joué, continue comme ça',
        'evidence': {
          'id': 'ev-3',
          'questId': 'q-1',
          'proofType': 'photo',
          'textContent': null,
          'fileId': 'f-3',
          'description': 'Séance de 45 minutes ce matin',
          'quest': {'title': 'Gym 3x par semaine'},
        },
      });

      expect(request.comment, 'Bien joué, continue comme ça');
      expect(request.description, 'Séance de 45 minutes ce matin');
    });

    test('leaves comment and description null when absent from the payload', () {
      final request = AllyValidationRequest.fromJson({
        'id': 'val-4',
        'evidenceId': 'ev-4',
        'status': 'pending',
        'evidence': {
          'id': 'ev-4',
          'questId': 'q-1',
          'proofType': 'text',
          'textContent': 'Fait',
          'fileId': null,
          'quest': {'title': 'Lire 20 minutes'},
        },
      });

      expect(request.comment, isNull);
      expect(request.description, isNull);
    });
  });
}
