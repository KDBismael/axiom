import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../controllers/guided_tour_controller.dart';
import '../models/first_quest_template.dart';

/// Guided tour step 1: pick a ready-made first quest (solo, no stake) or
/// fall back to the full creation wizard.
Future<void> showFirstQuestSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => const _FirstQuestSheet(),
  );
}

class _FirstQuestSheet extends StatefulWidget {
  const _FirstQuestSheet();

  @override
  State<_FirstQuestSheet> createState() => _FirstQuestSheetState();
}

class _FirstQuestSheetState extends State<_FirstQuestSheet> {
  final _tour = Get.find<GuidedTourController>();
  FirstQuestTemplate? _pending;

  Future<void> _launch(FirstQuestTemplate template) async {
    if (_pending != null) return;
    setState(() => _pending = template);
    final created = await _tour.launchTemplate(template);
    if (!mounted) return;
    setState(() => _pending = null);
    if (created == null) return;
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.firstQuestLaunched);
  }

  void _custom() {
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.questCreate);
  }

  void _skip() {
    Navigator.of(context).pop();
    _tour.finish();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ÉTAPE 1/3',
          style: AppTypography.labelMd.copyWith(
            fontSize: 10.5,
            color: AppColors.volt,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choisis ta première quête',
          style: AppTypography.headlineMd.copyWith(
            fontSize: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Commence simple : sans mise, sans preuve. Tu pourras créer des '
          'quêtes plus ambitieuses ensuite.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.outline),
        ),
        const SizedBox(height: 16),
        for (final template in firstQuestTemplates) ...[
          _TemplateCard(
            template: template,
            loading: _pending == template,
            onTap: _pending == null ? () => _launch(template) : null,
          ),
          const SizedBox(height: 10),
        ],
        Obx(() {
          final error = _tour.errorMessage.value;
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.errorSoft,
              ),
            ),
          );
        }),
        TextButton(
          onPressed: _pending == null ? _custom : null,
          child: Text(
            'CRÉER MA PROPRE QUÊTE',
            style: AppTypography.labelMd.copyWith(color: AppColors.volt),
          ),
        ),
        TextButton(
          onPressed: _pending == null ? _skip : null,
          child: Text(
            'Passer le guide',
            style: AppTypography.labelMd.copyWith(
              fontSize: 11,
              color: AppColors.outlineMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.loading,
    required this.onTap,
  });

  final FirstQuestTemplate template;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: AppRadii.structuralRadius,
      child: InkWell(
        borderRadius: AppRadii.structuralRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.structuralRadius,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Text(template.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.summary,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.outlineMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                const Text(
                  '→',
                  style: TextStyle(fontSize: 18, color: AppColors.volt),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
