import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/profile_model.dart';
import '../services/avatar_picker_service.dart';

/// Thrown when the backend rejects a profile request; [message] is the
/// backend's own French-language message, ready to show directly in the UI.
class ProfileException implements Exception {
  ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileRepository {
  ProfileRepository(this._client);

  final ApiClient _client;

  Future<Profile> getMe() async {
    final response = await _client.get('/profile/me');
    if (!response.isOk || response.body == null) {
      throw ProfileException(_extractMessage(response.body));
    }
    return Profile.fromJson(response.body as Map<String, dynamic>);
  }

  Future<Profile> updateMe(Map<String, dynamic> changes) async {
    final response = await _client.patch('/profile/me', changes);
    if (!response.isOk || response.body == null) {
      throw ProfileException(_extractMessage(response.body));
    }
    return Profile.fromJson(response.body as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(PickedAvatar picked) async {
    final formData = FormData({
      'file': MultipartFile(
        picked.bytes,
        filename: picked.filename,
        contentType: picked.mimeType,
      ),
      'purpose': 'avatar',
    });
    final response = await _client.post('/files/upload', formData);
    if (!response.isOk || response.body == null) {
      throw ProfileException(_extractMessage(response.body));
    }
    final json = response.body as Map<String, dynamic>;
    return json['id'] as String;
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
