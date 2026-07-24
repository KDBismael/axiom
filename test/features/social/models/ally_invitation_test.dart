import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/social/models/ally_invitation.dart';

void main() {
  group('AllyInvitation.fromJson', () {
    test('parses the full shape', () {
      final invitation = AllyInvitation.fromJson({
        'id': 'inv-1',
        'token': 'tok-abc',
        'deepLink': 'axiom://invite?token=tok-abc',
        'status': 'pending',
        'expiresAt': '2026-01-08T00:00:00.000Z',
      });

      expect(invitation.id, 'inv-1');
      expect(invitation.token, 'tok-abc');
      expect(invitation.deepLink, 'axiom://invite?token=tok-abc');
      expect(invitation.status, InvitationStatus.pending);
      expect(invitation.expiresAt, DateTime.parse('2026-01-08T00:00:00.000Z'));
    });

    test('token and deepLink are null for a listed (already-persisted) invitation', () {
      final invitation = AllyInvitation.fromJson({
        'id': 'inv-1',
        'status': 'pending',
        'expiresAt': '2026-01-08T00:00:00.000Z',
      });

      expect(invitation.token, isNull);
      expect(invitation.deepLink, isNull);
    });

    test('parses each status value', () {
      for (final entry in {
        'pending': InvitationStatus.pending,
        'accepted': InvitationStatus.accepted,
        'declined': InvitationStatus.declined,
        'expired': InvitationStatus.expired,
      }.entries) {
        final invitation = AllyInvitation.fromJson({
          'id': 'inv-1',
          'token': 'tok-abc',
          'deepLink': 'axiom://invite?token=tok-abc',
          'status': entry.key,
          'expiresAt': '2026-01-08T00:00:00.000Z',
        });
        expect(invitation.status, entry.value);
      }
    });
  });
}
