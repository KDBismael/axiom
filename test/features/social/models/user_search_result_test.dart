import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/social/models/user_search_result.dart';

void main() {
  test('UserSearchResult.fromJson parses a search hit', () {
    final result = UserSearchResult.fromJson({
      'id': 'u-4',
      'firstName': 'Awa',
      'lastName': 'Traore',
      'avatarUrl': null,
    });

    expect(result.id, 'u-4');
    expect(result.firstName, 'Awa');
    expect(result.lastName, 'Traore');
    expect(result.avatarUrl, isNull);
  });
}
