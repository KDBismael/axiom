import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/profile/models/profile_model.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses the full backend shape', () {
      final json = {
        'id': 'u-1',
        'email': 'jean@axiom.com',
        'phone': '+2250700000000',
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'avatarUrl': '/files/f-1',
        'language': 'fr',
        'role': 'user',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'notificationsEnabled': true,
        'privacyLevel': 'standard',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'u-1');
      expect(profile.email, 'jean@axiom.com');
      expect(profile.phone, '+2250700000000');
      expect(profile.firstName, 'Jean');
      expect(profile.lastName, 'Dupont');
      expect(profile.avatarUrl, '/files/f-1');
      expect(profile.language, 'fr');
      expect(profile.role, 'user');
      expect(profile.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(profile.updatedAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
      expect(profile.notificationsEnabled, isTrue);
      expect(profile.privacyLevel, ProfilePrivacyLevel.standard);
    });

    test('parses privacyLevel: private', () {
      final json = {
        'id': 'u-1',
        'email': 'jean@axiom.com',
        'phone': null,
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'avatarUrl': null,
        'language': 'fr',
        'role': 'user',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'notificationsEnabled': false,
        'privacyLevel': 'private',
      };

      final profile = Profile.fromJson(json);

      expect(profile.privacyLevel, ProfilePrivacyLevel.private);
      expect(profile.notificationsEnabled, isFalse);
      expect(profile.phone, isNull);
      expect(profile.avatarUrl, isNull);
    });
  });

  group('ProfilePrivacyLevel', () {
    test('toJson round-trips to the backend string', () {
      expect(ProfilePrivacyLevel.standard.toJson(), 'standard');
      expect(ProfilePrivacyLevel.private.toJson(), 'private');
    });
  });
}
