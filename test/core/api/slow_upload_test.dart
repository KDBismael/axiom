import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  test(
    'multipart has its own long budget while ordinary requests retain their short timeout',
    () async {
      final storage = MockStorage();
      when(
        () => storage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'qa-access');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final receivedAuth = <String, String?>{};
      server.listen((request) async {
        receivedAuth[request.uri.path] = request.headers.value('authorization');
        await request.drain<void>();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'id': 'file-qa'}));
        await request.response.close();
      });
      final client = ApiClient(
        tokenStorage: TokenStorage(storage: storage),
        uploadTimeout: const Duration(seconds: 5),
      );
      client.onInit();
      client.httpClient.baseUrl = 'http://127.0.0.1:${server.port}';
      client.httpClient.timeout = const Duration(milliseconds: 50);
      try {
        final responses = await Future.wait([
          client.post<dynamic>(
            '/files/upload',
            FormData({
              'file': MultipartFile(
                Uint8List.fromList([1, 2, 3]),
                filename: 'proof.png',
              ),
              'purpose': 'quest_evidence',
            }),
          ),
          client.get<dynamic>('/ordinary'),
        ]);
        expect(responses[0].isOk, isTrue);
        expect(responses[0].body['id'], 'file-qa');
        expect(responses[1].isOk, isFalse);
        expect(receivedAuth['/files/upload'], 'Bearer qa-access');
        expect(client.httpClient.timeout, const Duration(milliseconds: 50));
      } finally {
        client.dispose();
        await server.close(force: true);
      }
    },
  );
}
