import 'package:flutter/material.dart';
import '../../api/authenticated_media_url.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import 'evidence_media_viewer.dart';

/// A rectangular (not circular) preview of an evidence photo — tapping
/// opens it full-screen, with swiping to the other photos in [allPaths] if
/// there's more than one.
class EvidencePhotoThumbnail extends StatelessWidget {
  const EvidencePhotoThumbnail({
    super.key,
    required this.path,
    required this.allPaths,
    required this.index,
    this.size = 160,
  });

  final String path;
  final List<String> allPaths;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showEvidenceImageViewer(context, imagePaths: allPaths, initialIndex: index),
      child: FutureBuilder<(String, Map<String, String>?)>(
        future: resolveAuthenticatedMedia(path),
        builder: (context, snapshot) {
          final data = snapshot.data;
          return ClipRRect(
            borderRadius: AppRadii.interactiveRadius,
            child: data == null
                ? Container(width: size, height: size, color: AppColors.surfaceContainerHigh)
                : Image.network(
                    data.$1,
                    headers: data.$2,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: size, height: size, color: AppColors.surfaceContainerHigh),
                  ),
          );
        },
      ),
    );
  }
}

/// A rectangular tile representing an evidence video — tapping opens a
/// full-screen player instead of just a filename/URL.
class EvidenceVideoThumbnail extends StatelessWidget {
  const EvidenceVideoThumbnail({super.key, required this.path, this.size = 160});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showEvidenceVideoViewer(context, videoPath: path),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadii.interactiveRadius,
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: AppColors.emerald, size: 48),
        ),
      ),
    );
  }
}
