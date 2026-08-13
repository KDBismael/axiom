import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum GoogleAuthStage { nativeSignIn, tokenRetrieval }

class GoogleAuthException implements Exception {
  const GoogleAuthException({
    required this.stage,
    required this.code,
    required this.userMessage,
  });

  final GoogleAuthStage stage;
  final String code;
  final String userMessage;

  factory GoogleAuthException.fromPlatformException({
    required PlatformException error,
    required GoogleAuthStage stage,
  }) {
    final normalizedCode = error.code.toLowerCase();
    final normalizedMessage = (error.message ?? '').toLowerCase();

    if (normalizedCode.contains('cancel')) {
      return GoogleAuthException(
        stage: stage,
        code: error.code,
        userMessage: 'Connexion Google annulée.',
      );
    }
    if (normalizedCode.contains('network')) {
      return GoogleAuthException(
        stage: stage,
        code: error.code,
        userMessage: 'Connexion réseau indisponible. Veuillez réessayer.',
      );
    }

    final isConfigurationError =
        normalizedCode.contains('developer') ||
        normalizedCode == '10' ||
        normalizedMessage.contains('developer_error') ||
        normalizedMessage.contains('10:') ||
        normalizedMessage.contains('error 10');
    return GoogleAuthException(
      stage: stage,
      code: error.code,
      userMessage: isConfigurationError && kDebugMode
          ? 'Configuration Google invalide (certificat OAuth Android).'
          : 'Google n’a pas pu valider la connexion. Veuillez réessayer.',
    );
  }

  @override
  String toString() => userMessage;
}

/// Thin wrapper around the native Google Sign-In SDK. Isolated behind this
/// class so [AuthController] can be unit-tested without touching native
/// code — tests fake this interface instead of the plugin itself.
class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        // Must be the Web client ID so the returned ID token's audience
        // matches the backend's GOOGLE_CLIENT_ID env var.
        serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      );

  final GoogleSignIn _googleSignIn;

  /// Runs the native Google sign-in flow and returns the ID token to send
  /// to POST /auth/google, or null if the user cancelled.
  Future<String?> signIn() async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (error) {
      throw _mapPlatformException(error, GoogleAuthStage.nativeSignIn);
    }
    if (account == null) return null;
    try {
      final auth = await account.authentication;
      if (auth.idToken == null) {
        _logFailure(GoogleAuthStage.tokenRetrieval, 'missing_id_token');
        throw const GoogleAuthException(
          stage: GoogleAuthStage.tokenRetrieval,
          code: 'missing_id_token',
          userMessage:
              'Google n’a pas pu valider la connexion. Veuillez réessayer.',
        );
      }
      return auth.idToken;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error, GoogleAuthStage.tokenRetrieval);
    }
  }

  GoogleAuthException _mapPlatformException(
    PlatformException error,
    GoogleAuthStage stage,
  ) {
    _logFailure(stage, error.code);
    return GoogleAuthException.fromPlatformException(
      error: error,
      stage: stage,
    );
  }

  void _logFailure(GoogleAuthStage stage, String code) {
    // Never log the ID token, account email, or native exception details.
    debugPrint('GoogleAuth failure stage=${stage.name} code=$code');
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
