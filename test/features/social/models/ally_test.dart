import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/social/models/ally.dart';

void main() {
  test('Ally.fromJson parses an accepted ally', () {
    final ally = Ally.fromJson({
      'userId': 'u-2',
      'firstName': 'Marie',
      'lastName': 'Kone',
      'avatarUrl': '/files/f-1',
    });

    expect(ally.id, 'u-2');
    expect(ally.firstName, 'Marie');
    expect(ally.lastName, 'Kone');
    expect(ally.avatarUrl, '/files/f-1');
  });

  test('Ally.fromJson handles a null avatarUrl', () {
    final ally = Ally.fromJson({
      'userId': 'u-2',
      'firstName': 'Marie',
      'lastName': 'Kone',
      'avatarUrl': null,
    });

    expect(ally.avatarUrl, isNull);
  });

  test('Ally.fromJson falls back to empty names when the profile is missing', () {
    final ally = Ally.fromJson({
      'userId': 'u-2',
      'firstName': null,
      'lastName': null,
      'avatarUrl': null,
    });

    expect(ally.firstName, '');
    expect(ally.lastName, '');
  });
}
