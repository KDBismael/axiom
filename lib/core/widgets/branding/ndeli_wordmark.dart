import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The "Ndeli — Arène" brand mark: a rotated volt-green square next to the
/// NDELI wordmark in Unbounded. Used in place of a bitmap logo in headers
/// (auth screen, invitation screens, etc) since it's just a rotated square.
class NdeliWordmark extends StatelessWidget {
  const NdeliWordmark({
    super.key,
    this.markSize = 16,
    this.fontSize = 22,
    this.showWordmark = true,
    this.color = AppColors.primary,
  });

  final double markSize;
  final double fontSize;
  final bool showWordmark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = Transform.rotate(
      angle: 0.7853981633974483, // 45deg
      child: Container(
        width: markSize,
        height: markSize,
        color: AppColors.volt,
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Text(
          'NDELI',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            letterSpacing: 0.02 * fontSize,
            color: color,
          ),
        ),
      ],
    );
  }
}
