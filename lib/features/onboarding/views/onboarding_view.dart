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
      eyebrow: '01 / 03',
      title: 'DES HABITUDES QUI TIENNENT',
      description:
          'Crée des quêtes quotidiennes ou hebdomadaires et suis ta '
          'progression jour après jour.',
      hero: _StreakHero(),
    ),
    _SlideContent(
      eyebrow: '02 / 03',
      title: 'ENGAGEZ VOTRE ARGENT',
      description: "Mets de l'argent réel en jeu pour rester motivé·e jusqu'au bout.",
      hero: _StakeHero(),
    ),
    _SlideContent(
      eyebrow: '03 / 03',
      title: 'RÉUSSISSEZ À PLUSIEURS',
      description: 'Invite des alliés qui valident tes preuves et te tiennent responsable.',
      hero: _AlliesHero(),
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Obx(
                      () => _PageIndicator(
                        count: OnboardingController.slideCount,
                        activeIndex: controller.currentPage.value,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'PASSER',
                        style: AppTypography.labelMd.copyWith(color: AppColors.outlineMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  children: [for (final slide in _slides) Center(child: slide.hero)],
                ),
              ),
              Obx(() {
                final slide = _slides[controller.currentPage.value];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.eyebrow,
                      style: AppTypography.labelMd.copyWith(color: AppColors.volt),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide.title,
                      style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.description,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline, fontSize: 15),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
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
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.hero,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget hero;
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 26 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.volt : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Slide 1 hero: a flame mark, a big streak number, and a 4-week grid.
class _StreakHero extends StatelessWidget {
  const _StreakHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: 0.7853981633974483,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.emberBright, AppColors.emberDeep],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Text('21', style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 56)),
            const SizedBox(width: 12),
            Text(
              'JOURS\nD\'AFFILÉE',
              style: AppTypography.labelMd.copyWith(color: AppColors.emberLight, height: 1.4),
            ),
          ],
        ),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(28, (i) {
            final color = i < 21
                ? (i > 17 ? AppColors.emberBright : AppColors.volt)
                : AppColors.surfaceContainerHighest;
            return DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
            );
          }),
        ),
      ],
    );
  }
}

/// Slide 2 hero: the tilted "en jeu" stake card + success/failure chips.
class _StakeHero extends StatelessWidget {
  const _StakeHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EN JEU',
          style: AppTypography.labelMd.copyWith(color: AppColors.outlineMuted),
        ),
        const SizedBox(height: 16),
        Transform.rotate(
          angle: -0.05,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: AppColors.volt,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: AppColors.voltShadow, offset: Offset(0, 8))],
            ),
            child: Column(
              children: [
                Text(
                  '25 000',
                  style: AppTypography.displayLg.copyWith(color: AppColors.onPrimary, fontSize: 46),
                ),
                const SizedBox(height: 6),
                Text(
                  'XOF · ENGAGÉS',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: [
            _pillChip('Réussite → remboursé', AppColors.outlineVariantStrong, AppColors.outline),
            _pillChip('Échec → aux alliés', AppColors.errorShadow, AppColors.errorSoft),
          ],
        ),
      ],
    );
  }

  Widget _pillChip(String label, Color border, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Text(label, style: AppTypography.bodyMd.copyWith(color: fg, fontSize: 13)),
    );
  }
}

/// Slide 3 hero: overlapping ally avatars + a couple of validation rows.
class _AlliesHero extends StatelessWidget {
  const _AlliesHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 76,
          child: Stack(
            children: [
              _avatar('AD', AppColors.violet, 0),
              _avatar('KH', AppColors.volt, 60, raised: true),
              _avatar('FS', AppColors.ember, 120),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _row('Awa a validé ta preuve', trailing: const Icon(Icons.check, color: AppColors.volt, size: 18)),
        const SizedBox(height: 8),
        _row(
          'Fatou attend ton verdict',
          trailing: Text(
            'À TOI',
            style: AppTypography.labelMd.copyWith(color: AppColors.emberLight, fontSize: 10.5),
          ),
        ),
      ],
    );
  }

  Widget _avatar(String initials, Color color, double left, {bool raised = false}) {
    return Positioned(
      left: left,
      top: raised ? 0 : 10,
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.surface, width: 4),
        ),
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _row(String label, {required Widget trailing}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.primary, fontSize: 14)),
          ),
          trailing,
        ],
      ),
    );
  }
}
