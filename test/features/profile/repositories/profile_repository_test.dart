import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/profile/repositories/profile_repository.dart';
import 'package:axiom/features/profile/services/avatar_picker_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ProfileRepository repository;

  final profileJson = {
    'id': 'u-1',
    'email': 'jean@axiom.com',
    'phone': '+2250700000000',
    'firstName': 'Jean',
    'lastName': 'Dupont',
    'avatarUrl': '/files/f-1',
    'language': 'fr',
    'role': 'user',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'notificationsEnabled': true,
    'privacyLevel': 'standard',
  };

  setUp(() {
    mockClient = MockApiClient();
    repository = ProfileRepository(mockClient);
  });

  group('ProfileRepository.getMe', () {
    test('GETs /profile/me and returns the parsed profile', () async {
      when(() => mockClient.get<dynamic>('/profile/me'))
          .thenAnswer((_) async => Response(statusCode: 200, body: profileJson));

      final profile = await repository.getMe();

      expect(profile.id, 'u-1');
      expect(profile.firstName, 'Jean');
    });

    test('throws ProfileException with the backend message on failure', () async {
      when(() => mockClient.get<dynamic>('/profile/me')).thenAnswer(
        (_) async => const Response(statusCode: 401, body: {'message': 'Non authentifié'}),
      );

      expect(
        () => repository.getMe(),
        throwsA(isA<ProfileException>().having((e) => e.message, 'message', 'Non authentifié')),
      );
    });
  });

  group('ProfileRepository.updateMe', () {
    test('PATCHes /profile/me with exactly the given partial map', () async {
      when(() => mockClient.patch<dynamic>('/profile/me', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: profileJson));

      await repository.updateMe({'firstName': 'Marc'});

      final captured = verify(() => mockClient.patch<dynamic>('/profile/me', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured, {'firstName': 'Marc'});
    });

    test('returns the updated profile', () async {
      when(() => mockClient.patch<dynamic>('/profile/me', any()))
          .thenAnswer((_) async => Response(statusCode: 200, body: profileJson));

      final profile = await repository.updateMe({'firstName': 'Marc'});

      expect(profile.firstName, 'Jean');
    });

    test('joins list-shaped validation messages with newlines on failure', () async {
      when(() => mockClient.patch<dynamic>('/profile/me', any())).thenAnswer(
        (_) async => Response(
          statusCode: 400,
          body: {
            'message': ['phone must be a valid phone number'],
          },
        ),
      );

      expect(
        () => repository.updateMe({'phone': 'bad'}),
        throwsA(
          isA<ProfileException>().having(
            (e) => e.message,
            'message',
            'phone must be a valid phone number',
          ),
        ),
      );
    });
  });

  group('ProfileRepository.uploadAvatar', () {
    final picked = PickedAvatar(
      bytes: Uint8List.fromList([1, 2, 3]),
      sizeBytes: 3,
      filename: 'avatar.png',
      mimeType: 'image/png',
    );

    test('posts multipart form data to /files/upload and returns the file id', () async {
      when(() => mockClient.post<dynamic>('/files/upload', any()))
          .thenAnswer((_) async => Response(statusCode: 201, body: {'id': 'f-2'}));

      final id = await repository.uploadAvatar(picked);

      expect(id, 'f-2');
      final captured = verify(() => mockClient.post<dynamic>('/files/upload', captureAny()))
          .captured
          .single as FormData;
      expect(captured.fields.single.key, 'purpose');
      expect(captured.fields.single.value, 'avatar');
      expect(captured.files.single.key, 'file');
      expect(captured.files.single.value.filename, 'avatar.png');
      expect(captured.files.single.value.contentType, 'image/png');
    });

    test('throws ProfileException on failure', () async {
      when(() => mockClient.post<dynamic>('/files/upload', any())).thenAnswer(
        (_) async => const Response(statusCode: 413, body: {'message': 'Fichier trop volumineux'}),
      );

      expect(
        () => repository.uploadAvatar(picked),
        throwsA(
          isA<ProfileException>().having((e) => e.message, 'message', 'Fichier trop volumineux'),
        ),
      );
    });
  });
}
