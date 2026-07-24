import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/services/deep_link_service.dart';

void main() {
  group('extractInviteToken', () {
    test('extracts the token from a valid invite link', () {
      expect(
        extractInviteToken(Uri.parse('axiom://invite/abc123')),
        'abc123',
      );
    });

    test('takes the first path segment when there are extras', () {
      expect(
        extractInviteToken(Uri.parse('axiom://invite/abc123/ignored')),
        'abc123',
      );
    });

    test('returns null for the wrong scheme', () {
      expect(
        extractInviteToken(Uri.parse('https://invite/abc123')),
        isNull,
      );
    });

    test('returns null for the wrong host', () {
      expect(
        extractInviteToken(Uri.parse('axiom://other/abc123')),
        isNull,
      );
    });

    test('returns null when there is no token segment', () {
      expect(extractInviteToken(Uri.parse('axiom://invite')), isNull);
      expect(extractInviteToken(Uri.parse('axiom://invite/')), isNull);
    });
  });
}
