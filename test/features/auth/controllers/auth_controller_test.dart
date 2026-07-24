import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/auth/controllers/auth_controller.dart';
import 'package:axiom/features/auth/models/user_model.dart';
import 'package:axiom/features/auth/repositories/auth_repository.dart';
import 'package:axiom/features/auth/services/apple_auth_service.dart';
import 'package:axiom/features/auth/services/google_auth_service.dart';
import 'package:axiom/core/api/token_storage.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockTokenStorage mockTokenStorage;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late AuthController controller;

  final testUser = User(
    id: 'u-1',
    email: 'jean@axiom.com',
    firstName: 'Jean',
    lastName: 'Dupont',
    role: 'user',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final authResult = AuthResult(user: testUser, accessToken: 'access-1', refreshToken: 'refresh-1');

  setUp(() {
    mockRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    controller = AuthController(
      authRepository: mockRepository,
      tokenStorage: mockTokenStorage,
      googleAuthService: mockGoogleAuthService,
      appleAuthService: mockAppleAuthService,
    );

    when(() => mockTokenStorage.saveTokenPair(access: any(named: 'access'), refresh: any(named: 'refresh')))
        .thenAnswer((_) async {});
    when(() => mockTokenStorage.clear()).thenAnswer((_) async {});
  });

  group('AuthController.login', () {
    test('success persists the token pair and sets the current user', () async {
      when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => authResult);

      await controller.login(email: 'jean@axiom.com', password: 'password123');

      verify(() => mockTokenStorage.saveTokenPair(access: 'access-1', refresh: 'refresh-1')).called(1);
      expect(controller.user.value, testUser);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.errorMessage.value, isNull);
      expect(controller.isLoading.value, isFalse);
      expect(controller.activeAction.value, isNull);
    });

    test('only marks activeAction as login while a login request is in flight', () async {
      final completer = Completer<AuthResult>();
      when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) => completer.future);

      final pending = controller.login(email: 'jean@axiom.com', password: 'password123');
      expect(controller.activeAction.value, AuthAction.login);
      expect(controller.isLoading.value, isTrue);

      completer.complete(authResult);
      await pending;

      expect(controller.activeAction.value, isNull);
      expect(controller.isLoading.value, isFalse);
    });

    test('failure surfaces the backend French message and leaves user null', () async {
      when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(AuthException('Identifiants incorrects'));

      await controller.login(email: 'jean@axiom.com', password: 'wrong');

      expect(controller.errorMessage.value, 'Identifiants incorrects');
      expect(controller.user.value, isNull);
      expect(controller.isAuthenticated, isFalse);
      verifyNever(() => mockTokenStorage.saveTokenPair(access: any(named: 'access'), refresh: any(named: 'refresh')));
    });
  });

  group('AuthController.restoreSession', () {
    test('with stored tokens, fetches and sets the current user', () async {
      when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
      when(() => mockRepository.fetchMe()).thenAnswer((_) async => testUser);

      await controller.restoreSession();

      expect(controller.user.value, testUser);
      verify(() => mockRepository.fetchMe()).called(1);
    });

    test('without stored tokens, leaves user null and skips the network call', () async {
      when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => false);

      await controller.restoreSession();

      expect(controller.user.value, isNull);
      verifyNever(() => mockRepository.fetchMe());
    });

    test('when fetchMe fails, clears storage and leaves user null', () async {
      when(() => mockTokenStorage.hasTokens()).thenAnswer((_) async => true);
      when(() => mockRepository.fetchMe()).thenThrow(AuthException('Non authentifié'));

      await controller.restoreSession();

      expect(controller.user.value, isNull);
      verify(() => mockTokenStorage.clear()).called(1);
    });
  });

  group('AuthController.logout', () {
    test('clears storage and the current user', () async {
      when(() => mockTokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
      when(() => mockRepository.logout(any())).thenAnswer((_) async {});
      controller.user.value = testUser;

      await controller.logout();

      verify(() => mockRepository.logout('refresh-1')).called(1);
      verify(() => mockTokenStorage.clear()).called(1);
      expect(controller.user.value, isNull);
    });

    test('still clears local state even if the server-side revoke fails', () async {
      when(() => mockTokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-1');
      when(() => mockRepository.logout(any())).thenThrow(AuthException('Erreur serveur'));
      controller.user.value = testUser;

      await controller.logout();

      verify(() => mockTokenStorage.clear()).called(1);
      expect(controller.user.value, isNull);
    });
  });

  group('AuthController.loginWithGoogle', () {
    test('activeAction is google (not login) while a Google request is in flight, so only '
        'the Google button shows a spinner', () async {
      final completer = Completer<AuthResult>();
      when(() => mockGoogleAuthService.signIn()).thenAnswer((_) async => 'google-id-token');
      when(() => mockRepository.loginWithGoogle(any())).thenAnswer((_) => completer.future);

      final pending = controller.loginWithGoogle();
      expect(controller.activeAction.value, AuthAction.google);
      expect(controller.activeAction.value, isNot(AuthAction.login));

      completer.complete(authResult);
      await pending;

      expect(controller.activeAction.value, isNull);
    });

    test('surfaces a generic French error, without crashing, when the native SDK throws '
        'something other than AuthException', () async {
      when(() => mockGoogleAuthService.signIn())
          .thenThrow(Exception('PlatformException(sign_in_failed, ...)'));

      await controller.loginWithGoogle();

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.isLoading.value, isFalse);
      expect(controller.activeAction.value, isNull);
      verifyNever(() => mockRepository.loginWithGoogle(any()));
    });
  });

  group('AuthController.loginWithApple', () {
    test('forwards the first-authorization name into the repository call', () async {
      when(() => mockAppleAuthService.signIn()).thenAnswer(
        (_) async => const AppleAuthPayload(idToken: 'apple-token', firstName: 'Jean', lastName: 'Dupont'),
      );
      when(
        () => mockRepository.loginWithApple(
          idToken: any(named: 'idToken'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async => authResult);

      await controller.loginWithApple();

      verify(
        () => mockRepository.loginWithApple(idToken: 'apple-token', firstName: 'Jean', lastName: 'Dupont'),
      ).called(1);
      expect(controller.user.value, testUser);
    });

    test('cancelled Apple sign-in surfaces an error without calling the repository', () async {
      when(() => mockAppleAuthService.signIn()).thenAnswer((_) async => null);

      await controller.loginWithApple();

      expect(controller.errorMessage.value, isNotNull);
      verifyNever(
        () => mockRepository.loginWithApple(
          idToken: any(named: 'idToken'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      );
    });
  });
}
