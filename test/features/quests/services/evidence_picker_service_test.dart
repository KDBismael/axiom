import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/services/evidence_picker_service.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  group('mimeTypeForFilename', () {
    test('maps common image extensions', () {
      expect(mimeTypeForFilename('photo.png'), 'image/png');
      expect(mimeTypeForFilename('photo.PNG'), 'image/png');
      expect(mimeTypeForFilename('photo.jpg'), 'image/jpeg');
      expect(mimeTypeForFilename('photo.jpeg'), 'image/jpeg');
      expect(mimeTypeForFilename('photo.webp'), 'image/webp');
      expect(mimeTypeForFilename('photo.gif'), 'image/gif');
    });

    test('maps common video extensions', () {
      expect(mimeTypeForFilename('clip.mp4'), 'video/mp4');
      expect(mimeTypeForFilename('clip.mov'), 'video/quicktime');
      expect(mimeTypeForFilename('clip.webm'), 'video/webm');
    });

    test('falls back to application/octet-stream for unknown extensions', () {
      expect(mimeTypeForFilename('mystery.xyz'), 'application/octet-stream');
      expect(mimeTypeForFilename('no-extension'), 'application/octet-stream');
    });

    test('handles image_picker-style UUID filenames', () {
      expect(
        mimeTypeForFilename(
          'image_picker_5B16A4E5-3659-4147-B5D3-45CDB2E2371D-2207-000001F441CD5839.png',
        ),
        'image/png',
      );
    });
  });

  group('EvidencePickerService', () {
    late MockImagePicker picker;
    late EvidencePickerService service;

    setUp(() {
      picker = MockImagePicker();
      service = EvidencePickerService(picker: picker);
    });

    test('captures a JPEG photo with quality 85', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'proof.jpg',
        mimeType: 'image/jpeg',
      );
      when(
        () => picker.pickImage(source: ImageSource.camera, imageQuality: 85),
      ).thenAnswer((_) async => file);

      final result = await service.pickPhoto(ImageSource.camera);

      expect(result?.mimeType, 'image/jpeg');
      verify(
        () => picker.pickImage(source: ImageSource.camera, imageQuality: 85),
      ).called(1);
    });

    test('records rear-camera video with a 30-second limit', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'proof.mp4',
        mimeType: 'video/mp4',
      );
      when(
        () => picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxDuration: maxEvidenceVideoDuration,
        ),
      ).thenAnswer((_) async => file);

      final result = await service.pickVideo(ImageSource.camera);

      expect(result?.mimeType, 'video/mp4');
      verify(
        () => picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxDuration: maxEvidenceVideoDuration,
        ),
      ).called(1);
    });

    test('rejects oversized photos before reading their bytes', () async {
      final file = XFile.fromData(
        Uint8List(0),
        name: 'large.jpg',
        mimeType: 'image/jpeg',
        length: maxEvidenceImageSizeBytes + 1,
      );
      when(
        () => picker.pickImage(source: ImageSource.gallery, imageQuality: 85),
      ).thenAnswer((_) async => file);

      expect(
        () => service.pickPhoto(ImageSource.gallery),
        throwsA(isA<EvidencePickerException>()),
      );
    });

    test('picks multiple gallery photos up to the given limit', () async {
      final files = [
        XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg', mimeType: 'image/jpeg'),
        XFile.fromData(Uint8List.fromList([2]), name: 'b.png', mimeType: 'image/png'),
      ];
      when(
        () => picker.pickMultiImage(imageQuality: 85, limit: 3),
      ).thenAnswer((_) async => files);

      final result = await service.pickMultiPhotos(limit: 3);

      expect(result.map((p) => p.mimeType), ['image/jpeg', 'image/png']);
      verify(() => picker.pickMultiImage(imageQuality: 85, limit: 3)).called(1);
    });

    test('truncates a multi-select result to the given limit', () async {
      final files = [
        XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg', mimeType: 'image/jpeg'),
        XFile.fromData(Uint8List.fromList([2]), name: 'b.jpg', mimeType: 'image/jpeg'),
        XFile.fromData(Uint8List.fromList([3]), name: 'c.jpg', mimeType: 'image/jpeg'),
      ];
      when(
        () => picker.pickMultiImage(imageQuality: 85, limit: 2),
      ).thenAnswer((_) async => files);

      final result = await service.pickMultiPhotos(limit: 2);

      expect(result.length, 2);
    });

    test('returns an empty list without calling the picker when limit is 0', () async {
      final result = await service.pickMultiPhotos(limit: 0);

      expect(result, isEmpty);
      verifyNever(() => picker.pickMultiImage(imageQuality: any(named: 'imageQuality')));
    });

    test('rejects an oversized photo within a multi-select batch', () async {
      final files = [
        XFile.fromData(
          Uint8List(0),
          name: 'large.jpg',
          mimeType: 'image/jpeg',
          length: maxEvidenceImageSizeBytes + 1,
        ),
      ];
      when(
        () => picker.pickMultiImage(imageQuality: 85, limit: 3),
      ).thenAnswer((_) async => files);

      expect(
        () => service.pickMultiPhotos(limit: 3),
        throwsA(isA<EvidencePickerException>()),
      );
    });

    test('rejects unsupported video types', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1]),
        name: 'proof.avi',
        mimeType: 'video/x-msvideo',
      );
      when(
        () => picker.pickVideo(
          source: ImageSource.gallery,
          preferredCameraDevice: CameraDevice.rear,
          maxDuration: maxEvidenceVideoDuration,
        ),
      ).thenAnswer((_) async => file);

      expect(
        () => service.pickVideo(ImageSource.gallery),
        throwsA(isA<EvidencePickerException>()),
      );
    });
  });
}
