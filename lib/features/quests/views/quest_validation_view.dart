import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_model.dart';

enum _EvidenceType { photo, video, file }

class QuestValidationView extends GetView<QuestListController> {
  const QuestValidationView({super.key});

  @override
  Widget build(BuildContext context) {
    final String questId = Get.arguments as String;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: GlassChrome(
              safeAreaTop: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      child: Icon(Icons.person, size: 18, color: AppColors.outline),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AXIOM',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 20,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final quest = controller.findById(questId);
              if (quest == null) {
                return Center(
                  child: Text(
                    'Quête introuvable.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                );
              }
              return _ValidationBody(quest: quest);
            }),
          ),
        ],
      ),
    );
  }
}

class _ValidationBody extends StatefulWidget {
  const _ValidationBody({required this.quest});

  final QuestModel quest;

  @override
  State<_ValidationBody> createState() => _ValidationBodyState();
}

class _ValidationBodyState extends State<_ValidationBody> {
  final _descriptionController = TextEditingController();
  _EvidenceType _evidenceType = _EvidenceType.photo;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Get.find<QuestListController>().checkIn(widget.quest.id);
    Get.offNamed(AppRoutes.questCheckinStatus, arguments: widget.quest.id);
  }

  @override
  Widget build(BuildContext context) {
    final xp = 50 + widget.quest.total * 10;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MISSION ACCOMPLIE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'VALIDER VOTRE SUCCÈS',
            style: AppTypography.displayLg.copyWith(
              color: AppColors.primary,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'PREUVE VISUELLE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 8,
                  child: _EvidenceCard(
                    icon: Icons.photo_camera,
                    label: 'CAPTURES PHOTO',
                    large: true,
                    selected: _evidenceType == _EvidenceType.photo,
                    onTap: () => setState(() => _evidenceType = _EvidenceType.photo),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: _EvidenceCard(
                          icon: Icons.videocam,
                          label: 'VIDÉO',
                          selected: _evidenceType == _EvidenceType.video,
                          onTap: () =>
                              setState(() => _evidenceType = _EvidenceType.video),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _EvidenceCard(
                          icon: Icons.file_present,
                          label: 'FICHIER',
                          selected: _evidenceType == _EvidenceType.file,
                          onTap: () =>
                              setState(() => _evidenceType = _EvidenceType.file),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'RÉCIT DE PERFORMANCE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              hintText: 'Décrivez votre exécution ici...',
              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outlineVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: AppRadii.structuralRadius,
                borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.structuralRadius,
                borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primaryFixed),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadii.structuralRadius,
              border: Border.all(color: AppColors.outlineVariant15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBJECTIF',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.quest.title,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'STATS',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$xp XP',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'SOUMETTRE POUR VALIDATION',
            variant: AppButtonVariant.lustre,
            trailingIcon: Icons.verified,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(
            color: selected ? AppColors.primaryFixed : AppColors.outlineVariant15,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (large)
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              )
            else
              Icon(icon, color: AppColors.outline, size: 22),
            if (!large) const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected ? AppColors.primary : AppColors.outline,
                fontSize: large ? 12 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
