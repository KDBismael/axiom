import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/progress/segmented_progress.dart';

/// The app's welcome/entry screen — shown once, before the first launch's
/// "onboarding completed" flag is set (see [OnboardingService]).
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  Future<void> _enterApp() async {
    await OnboardingService().markCompleted();
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(),
              const SizedBox(height: 56),
              const _QuestsCard(),
              const SizedBox(height: 16),
              const _CirclesCard(),
              const SizedBox(height: 16),
              const _StatementPanel(),
              const SizedBox(height: 56),
              _Footer(
                onGetStarted: _enterApp,
                onSignIn: () => Get.toNamed(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIENVENUE SUR',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.primary,
            letterSpacing: 0.2 * 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AXIOM',
          style: AppTypography.displayLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.primaryFixed, width: 2)),
          ),
          child: Text(
            'DISCIPLINE.\nRESPONSABILITÉ.\nPROGRÈS.',
            style: AppTypography.headlineMd.copyWith(
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "L'outil de performance ultime pour ceux qui exigent l'excellence. "
          'Transformez vos intentions en rituels de fer.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _QuestsCard extends StatelessWidget {
  const _QuestsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.1),
              borderRadius: AppRadii.interactiveRadius,
            ),
            child: const Icon(Icons.bolt, color: AppColors.primaryFixed),
          ),
          const SizedBox(height: 16),
          Text(
            'Quêtes de Haute Performance',
            style: AppTypography.titleLg.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ne vous contentez pas de listes de tâches. Nos Quêtes sont des '
            "missions structurées conçues pour briser l'inertie et forger de "
            'nouvelles habitudes en 21 jours.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 24),
          const SegmentedProgress(ratio: 0.6, segments: 5, height: 6),
        ],
      ),
    );
  }
}

class _CirclesCard extends StatelessWidget {
  const _CirclesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryFixed.withValues(alpha: 0.1),
                  width: 12,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadii.interactiveRadius,
                ),
                child: const Icon(Icons.group, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                "Cercles d'Engagement",
                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'La discipline est collective. Rejoignez des cercles restreints '
                'où chaque membre est responsable du succès des autres. '
                "L'échec n'est plus une option privée.",
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatementPanel extends StatelessWidget {
  const _StatementPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _StatusDot(color: AppColors.primaryFixed, label: 'SYSTÈME ACTIF'),
              const SizedBox(width: 16),
              _StatusDot(color: AppColors.outline, label: 'VÉRIFICATION'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Architecture du succès.',
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(color: AppColors.outline, fontSize: 10),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onGetStarted, required this.onSignIn});

  final Future<void> Function() onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRÊT POUR LE CHANGEMENT ?',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        Text(
          '"Le prix de la discipline est toujours inférieur au prix du regret."',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(label: 'COMMENCER', onPressed: onGetStarted),
        const SizedBox(height: 12),
        AppButton(
          label: "S'IDENTIFIER",
          variant: AppButtonVariant.secondary,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
