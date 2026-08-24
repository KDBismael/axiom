import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/onboarding_controller.dart';

/// The app's welcome/entry screen — a 3-slide swipeable intro shown once,
/// before the first launch's "onboarding completed" flag is set (see
/// [OnboardingController]/`OnboardingService`).
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _slides = [
    _SlideContent(
      icon: Icons.track_changes,
      title: 'DES HABITUDES QUI TIENNENT',
      description:
          'Créez des quêtes quotidiennes ou hebdomadaires et suivez votre '
          'progression jour après jour.',
    ),
    _SlideContent(
      icon: Icons.payments,
      title: 'ENGAGEZ VOTRE ARGENT',
      description:
          "Misez de l'argent réel sur votre engagement pour rester "
          "motivé jusqu'au bout.",
    ),
    _SlideContent(
      icon: Icons.groups,
      title: 'RÉUSSISSEZ À PLUSIEURS',
      description:
          'Invitez des alliés qui valident vos preuves et vous tiennent '
          'responsable.',
    ),
  ];

  Future<void> _finish() async {
    await controller.complete();
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'PASSER',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  children: [
                    for (final slide in _slides) _OnboardingSlide(slide),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => _PageIndicator(
                  count: OnboardingController.slideCount,
                  activeIndex: controller.currentPage.value,
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => AppButton(
                  label: controller.isLastPage ? 'COMMENCER' : 'SUIVANT',
                  onPressed: () async {
                    if (controller.isLastPage) {
                      await _finish();
                    } else {
                      await controller.advance();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideContent {
  const _SlideContent({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide(this.content);

  final _SlideContent content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(content.icon, size: 40, color: AppColors.primaryFixed),
          ),
          const SizedBox(height: 40),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.emerald
                : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
