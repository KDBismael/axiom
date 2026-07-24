import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Name/email captured on Apple's *first* authorization only — Apple never
/// shares it again on subsequent sign-ins, so the caller must forward it to
/// the backend the first time it's seen.
class AppleAuthPayload {
  const AppleAuthPayload({required this.idToken, this.firstName, this.lastName});

  final String idToken;
  final String? firstName;
  final String? lastName;
}

/// Thin wrapper around the native Sign in with Apple SDK. Isolated behind
/// this class so [AuthController] can be unit-tested without touching
/// native code — tests fake this interface instead of the plugin itself.
class AppleAuthService {
  Future<AppleAuthPayload?> signIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    if (credential.identityToken == null) return null;
    return AppleAuthPayload(
      idToken: credential.identityToken!,
      firstName: credential.givenName,
      lastName: credential.familyName,
    );
  }
}
