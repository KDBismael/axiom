import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/auth/repositories/auth_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late AuthRepository repository;

  final userJson = {
    'id': 'u-1',
    'email': 'jean@axiom.com',
    'firstName': 'Jean',
    'lastName': 'Dupont',
    'phone': null,
    'avatarUrl': null,
    'role': 'user',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };

  final successBody = {
    'accessToken': 'access-1',
    'refreshToken': 'refresh-1',
    'user': userJson,
  };

  setUp(() {
    mockClient = MockApiClient();
    repository = AuthRepository(mockClient);
  });

  group('AuthRepository', () {
    test('register posts to /auth/register and returns an AuthResult', () async {
      when(() => mockClient.post<dynamic>('/auth/register', any()))
          .thenAnswer((_) async => Response(statusCode: 201, body: successBody));

      final result = await repository.register(
        email: 'jean@axiom.com',
        password: 'password123',
        firstName: 'Jean',
        lastName: 'Dupont',
      );

      final captured = verify(() => mockClient.post<dynamic>('/auth/register', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['email'], 'jean@axiom.com');
      expect(captured['password'], 'password123');
      expect(result.user.email, 'jean@axiom.com');
      expect(result.accessToken, 'access-1');
      expect(result.refreshToken, 'refresh-1');
    });

    test('login posts to /auth/login and returns an AuthResult', () async {
      when(() => mockClient.post<dynamic>('/auth/login', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: successBody));

      final result = await repository.login(email: 'jean@axiom.com', password: 'password123');

      expect(result.user.id, 'u-1');
    });

    test('login throws AuthException with backend French message on failure', () async {
      when(() => mockClient.post<dynamic>('/auth/login', any())).thenAnswer(
        (_) async => Response(
          statusCode: 401,
          body: {'message': 'Identifiants incorrects'},
        ),
      );

      expect(
        () => repository.login(email: 'jean@axiom.com', password: 'wrong'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', 'Identifiants incorrects'),
        ),
      );
    });

    test('login joins list-shaped validation messages with newlines', () async {
      when(() => mockClient.post<dynamic>('/auth/login', any())).thenAnswer(
        (_) async => Response(
          statusCode: 400,
          body: {
            'message': ['email must be an email', 'password is too short'],
          },
        ),
      );

      expect(
        () => repository.login(email: 'bad', password: '1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'email must be an email\npassword is too short',
          ),
        ),
      );
    });

    test('loginWithGoogle posts the ID token to /auth/google', () async {
      when(() => mockClient.post<dynamic>('/auth/google', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: successBody));

      final result = await repository.loginWithGoogle('google-id-token');

      final captured = verify(() => mockClient.post<dynamic>('/auth/google', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['idToken'], 'google-id-token');
      expect(result.user.id, 'u-1');
    });

    test('loginWithApple forwards idToken and first-authorization name', () async {
      when(() => mockClient.post<dynamic>('/auth/apple', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: successBody));

      await repository.loginWithApple(
        idToken: 'apple-id-token',
        firstName: 'Jean',
        lastName: 'Dupont',
      );

      final captured = verify(() => mockClient.post<dynamic>('/auth/apple', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['idToken'], 'apple-id-token');
      expect(captured['firstName'], 'Jean');
      expect(captured['lastName'], 'Dupont');
    });

    test('refresh posts the refresh token and returns a rotated pair', () async {
      when(() => mockClient.post<dynamic>('/auth/refresh', any())).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          body: {'accessToken': 'access-2', 'refreshToken': 'refresh-2', 'user': userJson},
        ),
      );

      final result = await repository.refresh('refresh-1');

      expect(result.accessToken, 'access-2');
      expect(result.refreshToken, 'refresh-2');
    });

    test('logout posts the refresh token and succeeds on 200', () async {
      when(() => mockClient.post<dynamic>('/auth/logout', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.logout('refresh-1');

      verify(() => mockClient.post<dynamic>('/auth/logout', {'refreshToken': 'refresh-1'}))
          .called(1);
    });

    test('fetchMe returns the current user from /auth/me', () async {
      when(() => mockClient.get<dynamic>('/auth/me'))
          .thenAnswer((_) async => Response(statusCode: 200, body: userJson));

      final user = await repository.fetchMe();

      expect(user.id, 'u-1');
      expect(user.email, 'jean@axiom.com');
    });

    test('fetchMe throws AuthException on failure', () async {
      when(() => mockClient.get<dynamic>('/auth/me')).thenAnswer(
        (_) async => const Response(statusCode: 401, body: {'message': 'Non authentifié'}),
      );

      expect(
        () => repository.fetchMe(),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Non authentifié')),
      );
    });
  });
}
