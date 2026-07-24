import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/auth/models/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('parses all backend fields', () {
      final json = {
        'id': 'u-1',
        'email': 'jean@axiom.com',
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'phone': '+2250700000000',
        'avatarUrl': 'https://example.com/avatar.png',
        'role': 'user',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'u-1');
      expect(user.email, 'jean@axiom.com');
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
      expect(user.phone, '+2250700000000');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.role, 'user');
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(user.updatedAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
    });

    test('handles nullable phone and avatarUrl', () {
      final json = {
        'id': 'u-2',
        'email': 'marie@axiom.com',
        'firstName': 'Marie',
        'lastName': 'Kone',
        'phone': null,
        'avatarUrl': null,
        'role': 'user',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
    });
  });
}
