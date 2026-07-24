import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/social/models/ally_request.dart';

void main() {
  group('AllyRequest.fromJson', () {
    test('parses an incoming pending request', () {
      final request = AllyRequest.fromJson({
        'id': 'req-1',
        'direction': 'incoming',
        'status': 'pending',
        'otherUser': {
          'id': 'u-2',
          'firstName': 'Marie',
          'lastName': 'Kone',
          'avatarUrl': null,
        },
      });

      expect(request.id, 'req-1');
      expect(request.direction, AllyRequestDirection.incoming);
      expect(request.status, AllyRequestStatus.pending);
      expect(request.otherUser.firstName, 'Marie');
    });

    test('parses an outgoing accepted request', () {
      final request = AllyRequest.fromJson({
        'id': 'req-2',
        'direction': 'outgoing',
        'status': 'accepted',
        'otherUser': {
          'id': 'u-3',
          'firstName': 'Jean',
          'lastName': 'Dupont',
          'avatarUrl': '/files/f-1',
        },
      });

      expect(request.direction, AllyRequestDirection.outgoing);
      expect(request.status, AllyRequestStatus.accepted);
      expect(request.otherUser.avatarUrl, '/files/f-1');
    });
  });
}
