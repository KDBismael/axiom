import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// The explanation bubble shown next to a highlighted element.
class TourBubble extends StatelessWidget {
  const TourBubble({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String step;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.volt.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step,
            style: AppTypography.labelMd.copyWith(
              fontSize: 10.5,
              color: AppColors.volt,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.headlineMd.copyWith(
              fontSize: 18,
              height: 1.2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.outline,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTypography.labelMd.copyWith(color: AppColors.volt),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
