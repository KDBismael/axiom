import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Result of a successful pick — everything [ProfileRepository.uploadAvatar]
/// needs, independent of how the bytes were obtained.
class PickedAvatar {
  const PickedAvatar({
    required this.bytes,
    required this.sizeBytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final int sizeBytes;
  final String filename;
  final String mimeType;
}

/// Thin wrapper around the native image picker. Isolated behind this class
/// so [ProfileController] can be unit-tested without touching native code —
/// tests fake this interface instead of the plugin itself.
class AvatarPickerService {
  /// imageQuality forces the plugin to re-encode the picked image as JPEG on
  /// both iOS and Android — without it, iOS gallery photos are frequently
  /// HEIC, which the backend's upload allowlist rejects (only png/jpeg/webp/gif).
  Future<PickedAvatar?> pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedAvatar(
      bytes: bytes,
      sizeBytes: bytes.length,
      filename: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
    );
  }
}
