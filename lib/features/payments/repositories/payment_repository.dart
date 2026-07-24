import '../../../core/api/api_client.dart';
import '../models/stake_transaction.dart';

/// Thrown when the backend rejects a payment request; [message] is the
/// backend's own French-language message, ready to show directly in the UI.
class PaymentException implements Exception {
  PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentRepository {
  PaymentRepository(this._client);

  final ApiClient _client;

  /// Idempotent server-side: calling this again while a transaction is
  /// pending/processing returns the same one instead of double-charging.
  Future<StakeTransaction> initiateStakePayment(
    String questId, {
    String? phoneNumber,
  }) async {
    final response = await _client.post('/quests/$questId/stake/pay', {
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    });
    if (!response.isOk || response.body == null) {
      throw PaymentException(_extractMessage(response.body));
    }
    return StakeTransaction.fromJson(response.body as Map<String, dynamic>);
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
