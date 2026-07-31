import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../api/authenticated_media_url.dart';
import '../../theme/app_colors.dart';

/// Full-screen photo viewer with pinch-zoom, swipeable when there is more
/// than one photo (e.g. a multi-photo check-in proof).
Future<void> showEvidenceImageViewer(
  BuildContext context, {
  required List<String> imagePaths,
  int initialIndex = 0,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ImageViewerPage(imagePaths: imagePaths, initialIndex: initialIndex),
    ),
  );
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({required this.imagePaths, required this.initialIndex});

  final List<String> imagePaths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) => _ZoomableAuthenticatedImage(path: imagePaths[index]),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableAuthenticatedImage extends StatelessWidget {
  const _ZoomableAuthenticatedImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String, Map<String, String>?)>(
      future: resolveAuthenticatedMedia(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
        }
        final (url, headers) = snapshot.data!;
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(url, headers: headers, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}

/// Full-screen video player with play/pause and a seek bar.
Future<void> showEvidenceVideoViewer(BuildContext context, {required String videoPath}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) => _VideoViewerPage(videoPath: videoPath),
    ),
  );
}

class _VideoViewerPage extends StatefulWidget {
  const _VideoViewerPage({required this.videoPath});

  final String videoPath;

  @override
  State<_VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<_VideoViewerPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final (url, headers) = await resolveAuthenticatedMedia(widget.videoPath);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers ?? const {},
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: controller == null
                  ? const CircularProgressIndicator(color: AppColors.emerald)
                  : AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () => setState(
                          () => controller.value.isPlaying ? controller.pause() : controller.play(),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller),
                            if (!controller.value.isPlaying)
                              const Icon(Icons.play_arrow, color: Colors.white, size: 64),
                          ],
                        ),
                      ),
                    ),
            ),
            if (controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(playedColor: AppColors.emerald),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
