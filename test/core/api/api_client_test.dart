import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/core/api/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// A minimal local HTTP server standing in for axiom-backend, so we can
/// exercise ApiClient's real GetConnect request modifier/authenticator
/// pipeline (not just a mocked client) — including genuine concurrent
/// requests racing through addAuthenticator at the same time.
class _FakeBackend {
  _FakeBackend(this.server);

  final HttpServer server;
  int refreshCalls = 0;
  int protectedCalls = 0;

  /// When false, every /auth/refresh call fails (simulating a revoked or
  /// invalid refresh token).
  bool refreshSucceeds = true;

  static Future<_FakeBackend> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final backend = _FakeBackend(server);
    backend._serve();
    return backend;
  }

  void _serve() {
    server.listen((request) async {
      if (request.uri.path == '/auth/refresh') {
        refreshCalls++;
        // Let concurrent callers actually overlap in time rather than
        // resolving synchronously in request order.
        await Future.delayed(const Duration(milliseconds: 20));
        if (refreshSucceeds) {
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'accessToken': 'fresh-access-$refreshCalls',
              'refreshToken': 'fresh-refresh-$refreshCalls',
            }),
          );
        } else {
          request.response.statusCode = 401;
        }
        await request.response.close();
        return;
      }

      if (request.uri.path == '/protected') {
        protectedCalls++;
        final auth = request.headers.value('authorization');
        if (auth != null && auth.startsWith('Bearer fresh-access-')) {
          request.response.statusCode = 200;
          request.response.write('ok');
        } else {
          request.response.statusCode = 401;
        }
        await request.response.close();
        return;
      }

      request.response.statusCode = 404;
      await request.response.close();
    });
  }

  String get baseUrl =>
      'http://${server.address.address}:${server.port}';

  Future<void> close() => server.close(force: true);
}

void main() {
  late _FakeBackend backend;
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;
  late ApiClient apiClient;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The test binding installs an HttpOverrides that fakes every request
    // with a 400 — undo that so ApiClient's GetConnect client can make real
    // requests to our in-process fake backend below.
    HttpOverrides.global = null;
    Get.testMode = true;
  });

  setUp(() async {
    backend = await _FakeBackend.start();
    mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'stale-access');
    when(() => mockStorage.read(key: 'refresh_token'))
        .thenAnswer((_) async => 'stale-refresh');
    when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String;
      if (key == 'access_token') {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => value);
      } else if (key == 'refresh_token') {
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => value);
      }
    });
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    tokenStorage = TokenStorage(storage: mockStorage);
    apiClient = ApiClient(tokenStorage: tokenStorage);
    apiClient.onInit();
    apiClient.httpClient.baseUrl = backend.baseUrl;
  });

  tearDown(() async {
    await backend.close();
  });

  test(
    'concurrent 401s share a single /auth/refresh call',
    () async {
      final results = await Future.wait([
        apiClient.get<dynamic>('/protected'),
        apiClient.get<dynamic>('/protected'),
        apiClient.get<dynamic>('/protected'),
      ]);

      expect(results.every((r) => r.isOk), isTrue);
      expect(backend.refreshCalls, 1);
    },
  );

  test(
    'a failed refresh clears storage exactly once for concurrent failures',
    () async {
      backend.refreshSucceeds = false;

      await Future.wait([
        apiClient.get<dynamic>('/protected'),
        apiClient.get<dynamic>('/protected'),
        apiClient.get<dynamic>('/protected'),
      ]);

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    },
  );

  test(
    'a later independent failure can still trigger logout after a prior successful refresh',
    () async {
      await apiClient.get<dynamic>('/protected');
      expect(backend.refreshCalls, 1);

      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'stale-again');
      backend.refreshSucceeds = false;

      await apiClient.get<dynamic>('/protected');

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    },
  );
}
