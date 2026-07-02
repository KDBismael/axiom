import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// `surface` at 70% opacity for top and bottom app chrome.
///
/// The design spec calls for a 20px backdrop-blur on top of this (true
/// glassmorphism), but `BackdropFilter` here bled blur across the whole
/// screen instead of staying clipped to this widget's bounds when combined
/// with the persistent bottom-nav shell (reproduced on-device, not a
/// simulator artifact) — dropped to a flat translucent surface so the shell
/// renders correctly; revisit the blur once isolated.
class GlassChrome extends StatelessWidget {
  const GlassChrome({
    super.key,
    required this.child,
    this.safeAreaTop = false,
    this.safeAreaBottom = false,
  });

  final Widget child;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: child),
    );
  }
}
