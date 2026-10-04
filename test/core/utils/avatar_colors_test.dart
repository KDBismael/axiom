import 'package:axiom/core/utils/avatar_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display names produce two initials', () {
    expect(initialsForDisplayName('ismael KDB'), 'IK');
    expect(initialsForDisplayName('  Kofi   A. '), 'KA');
    expect(initialsForDisplayName('Moussa'), 'MO');
    expect(initialsForDisplayName(''), '?');
  });

  test('avatar colors remain consistent for a user id', () {
    expect(avatarColorForId('user-1'), avatarColorForId('user-1'));
    expect(
      {for (var i = 0; i < 30; i++) avatarColorForId('user-$i')}.length,
      greaterThan(1),
    );
  });
}
