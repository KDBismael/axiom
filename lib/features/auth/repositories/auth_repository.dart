import '../../../core/api/api_client.dart';
import '../models/user_model.dart';

/// Thrown when the backend rejects an auth request; [message] is the
/// backend's own French-language message, ready to show directly in the UI.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.user, required this.accessToken, required this.refreshToken});

  final User user;
  final String accessToken;
  final String refreshToken;
}

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) {
    return _postForAuthResult('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
  }

  Future<AuthResult> login({required String email, required String password}) {
    return _postForAuthResult('/auth/login', {'email': email, 'password': password});
  }

  Future<AuthResult> loginWithGoogle(String idToken) {
    return _postForAuthResult('/auth/google', {'idToken': idToken});
  }

  Future<AuthResult> loginWithApple({
    required String idToken,
    String? firstName,
    String? lastName,
  }) {
    return _postForAuthResult('/auth/apple', {
      'idToken': idToken,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    });
  }

  Future<AuthResult> refresh(String refreshToken) {
    return _postForAuthResult('/auth/refresh', {'refreshToken': refreshToken});
  }

  Future<void> logout(String refreshToken) async {
    final response = await _client.post('/auth/logout', {'refreshToken': refreshToken});
    if (!response.isOk) {
      throw AuthException(_extractMessage(response.body));
    }
  }

  Future<User> fetchMe() async {
    final response = await _client.get('/auth/me');
    if (!response.isOk || response.body == null) {
      throw AuthException(_extractMessage(response.body));
    }
    return User.fromJson(response.body as Map<String, dynamic>);
  }

  Future<AuthResult> _postForAuthResult(String path, Map<String, dynamic> body) async {
    final response = await _client.post(path, body);
    if (!response.isOk || response.body == null) {
      throw AuthException(_extractMessage(response.body));
    }
    final json = response.body as Map<String, dynamic>;
    return AuthResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
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
