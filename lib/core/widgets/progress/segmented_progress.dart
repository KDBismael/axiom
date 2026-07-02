import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Segmented Monolith progress bar: flex blocks, filled = emerald.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.ratio,
    this.segments = 10,
    this.height = 8,
  });

  final double ratio;
  final int segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final filled = (ratio * segments).round().clamp(0, segments);
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(segments, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: index < filled
                    ? AppColors.emerald
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
