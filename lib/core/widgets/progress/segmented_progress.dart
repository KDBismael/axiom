import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Segmented Arène progress bar: flex blocks, filled = volt.
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

  /// Any started progress lights at least one segment, so a first
  /// check-in (3 %) visibly counts instead of leaving the bar empty.
  static int filledSegments(double ratio, int segments) {
    if (ratio <= 0) return 0;
    return (ratio * segments).round().clamp(1, segments);
  }

  @override
  Widget build(BuildContext context) {
    final filled = filledSegments(ratio, segments);
    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(segments, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: index < filled
                    ? AppColors.volt
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
