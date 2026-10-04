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

class EvidencePickerException implements Exception {
  const EvidencePickerException(this.message);

  final String message;
}

const maxEvidenceImageSizeBytes = 5 * 1024 * 1024;
const maxEvidenceVideoSizeBytes = 50 * 1024 * 1024;
const maxEvidenceVideoDuration = Duration(seconds: 30);

const _allowedPhotoMimeTypes = {
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
};

/// Thin wrapper around the native image/video picker for quest proof
/// evidence. Isolated behind this class so quest controllers can be
/// unit-tested without touching native code — tests fake this interface
/// instead of the plugin itself.
class EvidencePickerService {
  EvidencePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// imageQuality forces the plugin to re-encode the picked image as JPEG on
  /// both iOS and Android — without it, iOS gallery photos are frequently
  /// HEIC, which the backend's upload allowlist rejects (only png/jpeg/webp/gif).
  Future<PickedEvidence?> pickPhoto(ImageSource source) => _pick(
    () => _picker.pickImage(source: source, imageQuality: 85),
    allowedMimeTypes: _allowedPhotoMimeTypes,
    maxSizeBytes: maxEvidenceImageSizeBytes,
    oversizedMessage: 'Photo trop volumineuse (max 5 Mo).',
  );

  /// Gallery only — multi-select, capped at [limit] so the caller's own
  /// slot limit (e.g. 3 evidence photos) can't be exceeded even on
  /// platforms where the native picker ignores `limit`.
  Future<List<PickedEvidence>> pickMultiPhotos({required int limit}) async {
    if (limit <= 0) return const [];
    final files = await _picker.pickMultiImage(imageQuality: 85, limit: limit);
    final picked = <PickedEvidence>[];
    for (final file in files.take(limit)) {
      final mimeType = file.mimeType ?? mimeTypeForFilename(file.name);
      if (!_allowedPhotoMimeTypes.contains(mimeType)) {
        throw const EvidencePickerException('Type de fichier non supporté.');
      }
      final sizeBytes = await file.length();
      if (sizeBytes > maxEvidenceImageSizeBytes) {
        throw const EvidencePickerException('Photo trop volumineuse (max 5 Mo).');
      }
      picked.add(
        PickedEvidence(
          bytes: await file.readAsBytes(),
          sizeBytes: sizeBytes,
          filename: file.name,
          mimeType: mimeType,
        ),
      );
    }
    return picked;
  }

  Future<PickedEvidence?> pickVideo(ImageSource source) => _pick(
    () => _picker.pickVideo(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      maxDuration: maxEvidenceVideoDuration,
    ),
    allowedMimeTypes: const {'video/mp4', 'video/quicktime', 'video/webm'},
    maxSizeBytes: maxEvidenceVideoSizeBytes,
    oversizedMessage:
        'Vidéo trop volumineuse (max 50 Mo). Enregistrez un clip plus court.',
  );

  Future<PickedEvidence?> _pick(
    Future<XFile?> Function() pick, {
    required Set<String> allowedMimeTypes,
    required int maxSizeBytes,
    required String oversizedMessage,
  }) async {
    final file = await pick();
    if (file == null) return null;
    final mimeType = file.mimeType ?? mimeTypeForFilename(file.name);
    if (!allowedMimeTypes.contains(mimeType)) {
      throw const EvidencePickerException('Type de fichier non supporté.');
    }
    final sizeBytes = await file.length();
    if (sizeBytes > maxSizeBytes) {
      throw EvidencePickerException(oversizedMessage);
    }
    final bytes = await file.readAsBytes();
    return PickedEvidence(
      bytes: bytes,
      sizeBytes: sizeBytes,
      filename: file.name,
      mimeType: mimeType,
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
