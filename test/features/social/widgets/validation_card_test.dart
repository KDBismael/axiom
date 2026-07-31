import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/social/widgets/validation_card.dart';

void main() {
  group('validateDecisionComment', () {
    test('allows approving with an empty comment', () {
      expect(validateDecisionComment(approved: true, comment: ''), null);
    });

    test('allows approving with a non-empty comment', () {
      expect(validateDecisionComment(approved: true, comment: 'Bravo !'), null);
    });

    test('rejects an empty comment when rejecting', () {
      expect(
        validateDecisionComment(approved: false, comment: ''),
        'Un commentaire est requis pour justifier un rejet.',
      );
    });

    test('rejects a whitespace-only comment when rejecting', () {
      expect(
        validateDecisionComment(approved: false, comment: '   '),
        'Un commentaire est requis pour justifier un rejet.',
      );
    });

    test('allows rejecting with a non-empty comment', () {
      expect(validateDecisionComment(approved: false, comment: 'Photo floue'), null);
    });
  });
}
