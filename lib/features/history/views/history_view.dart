import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';

/// "History" tab — placeholder pending a real check-in history feature.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: GlassChrome(
            safeAreaTop: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HISTORIQUE',
                  style: AppTypography.titleLg.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Aucun historique pour l\'instant. Les quêtes complétées et échouées apparaîtront ici.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
