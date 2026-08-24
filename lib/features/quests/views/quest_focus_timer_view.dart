import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/focus_timer_controller.dart';

class QuestFocusTimerView extends StatelessWidget {
  const QuestFocusTimerView({super.key});

  @override
  Widget build(BuildContext context) {
    final questId = Get.arguments as String;
    final controller = Get.find<FocusTimerController>(tag: questId);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Obx(() {
                  final state = controller.state.value;
                  final elapsed = controller.elapsed.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MINUTEUR DE FOCUS',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _formatDuration(elapsed),
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.primary,
                          fontSize: 56,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (state) {
                          FocusTimerState.idle => 'Prêt à commencer',
                          FocusTimerState.running => 'En cours…',
                          FocusTimerState.paused => 'En pause',
                          FocusTimerState.finished => 'Session terminée',
                        },
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _Controls(controller: controller, state: state),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.state});

  final FocusTimerController controller;
  final FocusTimerState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case FocusTimerState.idle:
        return SizedBox(
          width: 200,
          child: AppButton(label: 'DÉMARRER', onPressed: controller.start),
        );
      case FocusTimerState.running:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'PAUSE',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: controller.pause,
            ),
            const SizedBox(width: 16),
            AppButton(
              label: 'TERMINER',
              fullWidth: false,
              onPressed: () => _finish(context),
            ),
          ],
        );
      case FocusTimerState.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'REPRENDRE',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: controller.resume,
            ),
            const SizedBox(width: 16),
            AppButton(
              label: 'TERMINER',
              fullWidth: false,
              onPressed: () => _finish(context),
            ),
          ],
        );
      case FocusTimerState.finished:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              child: AppButton(
                label: 'ENVOYER LE POINTAGE',
                onPressed: () => Get.offNamed(
                  AppRoutes.questValidation,
                  arguments: controller.questId,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.reset,
              child: const Text('RECOMMENCER'),
            ),
          ],
        );
    }
  }

  Future<void> _finish(BuildContext context) async {
    await controller.finish();
  }
}
