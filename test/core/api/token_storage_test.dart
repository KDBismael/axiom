import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);
  });

  group('TokenStorage', () {
    test('saveTokenPair writes both access and refresh tokens', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await tokenStorage.saveTokenPair(access: 'access-1', refresh: 'refresh-1');

      verify(() => mockStorage.write(key: 'access_token', value: 'access-1')).called(1);
      verify(() => mockStorage.write(key: 'refresh_token', value: 'refresh-1')).called(1);
    });

    test('readAccessToken returns the stored value', () async {
      when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'access-1');

      final token = await tokenStorage.readAccessToken();

      expect(token, 'access-1');
    });

    test('readRefreshToken returns the stored value', () async {
      when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'refresh-1');

      final token = await tokenStorage.readRefreshToken();

      expect(token, 'refresh-1');
    });

    test('hasTokens is true only when both tokens are present', () async {
      when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => 'access-1');
      when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'refresh-1');

      expect(await tokenStorage.hasTokens(), isTrue);
    });

    test('hasTokens is false when a token is missing', () async {
      when(() => mockStorage.read(key: 'access_token')).thenAnswer((_) async => null);
      when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'refresh-1');

      expect(await tokenStorage.hasTokens(), isFalse);
    });

    test('clear deletes both tokens', () async {
      when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      await tokenStorage.clear();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });
}
