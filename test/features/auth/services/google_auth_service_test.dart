import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/auth/services/google_auth_service.dart';

void main() {
  group('GoogleAuthException.fromPlatformException', () {
    test('maps cancellation to a cancellation message', () {
      final result = GoogleAuthException.fromPlatformException(
        error: PlatformException(code: 'sign_in_canceled'),
        stage: GoogleAuthStage.nativeSignIn,
      );

      expect(result.userMessage, 'Connexion Google annulée.');
    });

    test('maps network failures to a network-specific message', () {
      final result = GoogleAuthException.fromPlatformException(
        error: PlatformException(code: 'network_error'),
        stage: GoogleAuthStage.nativeSignIn,
      );

      expect(
        result.userMessage,
        'Connexion réseau indisponible. Veuillez réessayer.',
      );
    });

    test('recognizes the Android OAuth developer error', () {
      final result = GoogleAuthException.fromPlatformException(
        error: PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10:',
        ),
        stage: GoogleAuthStage.nativeSignIn,
      );

      expect(result.code, 'sign_in_failed');
      expect(result.stage, GoogleAuthStage.nativeSignIn);
      expect(result.userMessage, contains('Configuration Google invalide'));
    });
  });
}
