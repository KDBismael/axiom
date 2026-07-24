import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/services/evidence_picker_service.dart';

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
}
