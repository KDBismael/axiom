import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/quest_result_controller.dart';
import '../models/quest_result.dart';

class QuestResultView extends GetView<QuestResultController> {
  const QuestResultView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bilan de la quête'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Get.back<void>();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        },
      ),
    ),
    body: SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.errorMessage.value;
        final result = controller.result.value;
        if (error != null || result == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: AppColors.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error ?? 'Ce bilan est indisponible.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        return _ResultSummary(result: result);
      }),
    ),
  );
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});
  final QuestResult result;

  @override
  Widget build(BuildContext context) {
    final accent = result.isSuccess ? AppColors.volt : AppColors.error;
    final date = result.resolvedAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final avatar = result.ownerAvatarUrl;
    final initials = [
      result.ownerFirstName,
      result.ownerLastName,
    ].where((s) => s.isNotEmpty).map((s) => s.characters.first).take(2).join();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceContainerLow,
                foregroundColor: AppColors.primary,
                child: avatar != null && avatar.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatar,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(initials),
                        ),
                      )
                    : Text(initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.ownerName,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Icon(
            result.isSuccess
                ? Icons.emoji_events_outlined
                : Icons.flag_outlined,
            size: 64,
            color: accent,
          ),
          const SizedBox(height: 16),
          Text(
            result.isSuccess ? 'Quête réussie' : 'Quête échouée',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            result.title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadii.structuralRadius,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                Text(
                  result.percentageLabel,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Réalisation finale',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: result.completionPercent / 100,
                  color: accent,
                  backgroundColor: AppColors.outlineVariant,
                ),
                const SizedBox(height: 20),
                Text(
                  result.periodsLabel,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seuil de réussite : ${result.successThresholdPercent} %',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (result.isDeletionRejection) ...[
            Text(
              'La demande de suppression a été refusée par un allié. La quête est donc échouée, quel que soit son pourcentage de réalisation.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Bilan arrêté le $dateLabel',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
