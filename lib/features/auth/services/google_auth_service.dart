import 'package:google_sign_in/google_sign_in.dart';

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
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
