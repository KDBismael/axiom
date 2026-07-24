import '../../../core/api/api_client.dart';
import '../models/ally.dart';
import '../models/ally_invitation.dart';
import '../models/ally_request.dart';
import '../models/ally_validation_request.dart';
import '../models/user_search_result.dart';

/// Thrown when the backend rejects an allies/invitations/validations
/// request; [message] is the backend's own French-language message, ready
/// to show directly in the UI.
class SocialException implements Exception {
  SocialException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialRepository {
  SocialRepository(this._client);

  final ApiClient _client;

  Future<List<Ally>> fetchAllies() async {
    final response = await _client.get('/allies');
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => Ally.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AllyInvitation> createInvitation({String? inviteeContact}) async {
    final response = await _client.post('/allies/invitations', {
      if (inviteeContact != null) 'inviteeContact': inviteeContact,
    });
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    // The backend returns {invitation: {...}, token, deepLink} — the token
    // and deep link are only ever handed back at creation time.
    final body = response.body as Map<String, dynamic>;
    final invitation = body['invitation'] as Map<String, dynamic>;
    return AllyInvitation.fromJson({
      ...invitation,
      'token': body['token'],
      'deepLink': body['deepLink'],
    });
  }

  Future<List<AllyInvitation>> fetchInvitations() async {
    final response = await _client.get('/allies/invitations');
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => AllyInvitation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> redeemInvitation(String token) async {
    final response = await _client.post('/allies/invitations/redeem', {'token': token});
    if (!response.isOk) {
      throw SocialException(_extractMessage(response.body));
    }
  }

  Future<void> declineInvitation(String token) async {
    final response = await _client.post('/allies/invitations/decline', {'token': token});
    if (!response.isOk) {
      throw SocialException(_extractMessage(response.body));
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final response = await _client.get('/users/search', query: {'q': query});
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendAllyRequest(String recipientId) async {
    final response = await _client.post('/allies/requests', {'recipientId': recipientId});
    if (!response.isOk) {
      throw SocialException(_extractMessage(response.body));
    }
  }

  Future<List<AllyRequest>> fetchAllyRequests() async {
    final response = await _client.get('/allies/requests');
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => AllyRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> respondToAllyRequest(String id, {required bool accept}) async {
    final response = await _client.post(
      '/allies/requests/$id/respond',
      {'action': accept ? 'accept' : 'decline'},
    );
    if (!response.isOk) {
      throw SocialException(_extractMessage(response.body));
    }
  }

  Future<List<AllyValidationRequest>> fetchValidations({String? status}) async {
    final response = await _client.get(
      '/validations',
      query: status == null ? null : {'status': status},
    );
    if (!response.isOk || response.body == null) {
      throw SocialException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => AllyValidationRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> decideValidation(String id, {required bool approved}) async {
    final response = await _client.post(
      '/validations/$id/decision',
      {'decision': approved ? 'approved' : 'rejected'},
    );
    if (!response.isOk) {
      throw SocialException(_extractMessage(response.body));
    }
  }

  String _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is List) return message.join('\n');
      if (message is String) return message;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
