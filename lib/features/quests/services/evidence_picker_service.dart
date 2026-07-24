import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Result of a successful pick — everything [QuestRepository.uploadEvidenceFile]
/// needs, independent of how the bytes were obtained.
class PickedEvidence {
  const PickedEvidence({
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

/// Thin wrapper around the native image/video picker for quest proof
/// evidence. Isolated behind this class so quest controllers can be
/// unit-tested without touching native code — tests fake this interface
/// instead of the plugin itself.
class EvidencePickerService {
  Future<PickedEvidence?> pickPhoto() => _pick(() => ImagePicker().pickImage(source: ImageSource.gallery));

  Future<PickedEvidence?> pickVideo() => _pick(() => ImagePicker().pickVideo(source: ImageSource.gallery));

  Future<PickedEvidence?> _pick(Future<XFile?> Function() pick) async {
    final file = await pick();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedEvidence(
      bytes: bytes,
      sizeBytes: bytes.length,
      filename: file.name,
      mimeType: file.mimeType ?? mimeTypeForFilename(file.name),
    );
  }
}

/// XFile.mimeType is frequently null when picking from the gallery (notably
/// on iOS) — falls back to the file extension so a plain .png/.jpg still
/// gets a real image/* type instead of the generic application/octet-stream
/// the backend's upload allowlist rejects.
String mimeTypeForFilename(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return 'video/webm';
    default:
      return 'application/octet-stream';
  }
}
