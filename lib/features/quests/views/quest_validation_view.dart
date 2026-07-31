import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/quest_model.dart';
import '../repositories/quest_repository.dart';
import '../services/evidence_picker_service.dart';
import '../utils/period_progress.dart';

class QuestValidationView extends GetView<QuestListController> {
  const QuestValidationView({super.key});

  @override
  Widget build(BuildContext context) {
    final String questId = Get.arguments as String;

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                ),
                const Spacer(),
              ],
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

enum _EvidenceType { photo, video, text }

class _ValidationBody extends StatefulWidget {
  const _ValidationBody({required this.quest});

  final QuestModel quest;

  @override
  State<_ValidationBody> createState() => _ValidationBodyState();
}

const _maxPhotos = 3;

class _ValidationBodyState extends State<_ValidationBody> {
  final _descriptionController = TextEditingController();
  _EvidenceType _evidenceType = _EvidenceType.photo;
  PickedEvidence? _pickedVideo;
  final List<PickedEvidence> _pickedPhotos = [];
  bool _submitting = false;
  bool _loadingHistory = true;
  int _currentPeriodCount = 0;
  String? _error;

  bool get _periodComplete => _currentPeriodCount >= widget.quest.targetPerPeriod;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final checkIns = await Get.find<QuestListController>().fetchCheckIns(widget.quest.id);
    final count = countCheckInsInCurrentPeriod(
      checkIns,
      widget.quest.frequency,
      DateTime.now(),
    );
    setState(() {
      _loadingHistory = false;
      _currentPeriodCount = count;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final service = Get.find<EvidencePickerService>();
    final picked = await service.pickVideo();
    if (picked == null) return;
    setState(() => _pickedVideo = picked);
  }

  Future<void> _pickPhoto() async {
    if (_pickedPhotos.length >= _maxPhotos) return;
    final service = Get.find<EvidencePickerService>();
    final picked = await service.pickPhoto();
    if (picked == null) return;
    setState(() => _pickedPhotos.add(picked));
  }

  void _removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    final hasProof = _evidenceType == _EvidenceType.video
        ? _pickedVideo != null
        : _pickedPhotos.isNotEmpty;
    if (widget.quest.requiresProof && _evidenceType != _EvidenceType.text && !hasProof) {
      setState(() => _error = 'Une preuve est requise pour cette quête.');
      return;
    }
    if (_evidenceType == _EvidenceType.text && _descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez décrire votre exécution.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final controller = Get.find<QuestListController>();
    try {
      String? fileId;
      List<String>? fileIds;
      if (_evidenceType == _EvidenceType.video && _pickedVideo != null) {
        fileId = await controller.uploadEvidenceFile(_pickedVideo!);
      } else if (_evidenceType == _EvidenceType.photo && _pickedPhotos.isNotEmpty) {
        fileIds = [
          for (final photo in _pickedPhotos) await controller.uploadEvidenceFile(photo),
        ];
      }

      final proofType = switch (_evidenceType) {
        _EvidenceType.photo => ProofType.photo,
        _EvidenceType.video => ProofType.video,
        _EvidenceType.text => ProofType.text,
      };

      await controller.checkIn(
        widget.quest.id,
        proofType: (fileId != null || fileIds != null || _evidenceType == _EvidenceType.text)
            ? proofType
            : null,
        fileId: fileId,
        fileIds: fileIds,
        textContent: _evidenceType == _EvidenceType.text ? _descriptionController.text.trim() : null,
        description: _evidenceType != _EvidenceType.text && _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (!mounted) return;
      if (controller.errorMessage.value != null) {
        setState(() => _error = controller.errorMessage.value);
        return;
      }

      Get.offNamed(AppRoutes.questCheckinStatus, arguments: widget.quest.id);
    } on QuestException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = 50 + widget.quest.durationDays;
    final disabled = _submitting || _loadingHistory || _periodComplete;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
          if (!_loadingHistory && _periodComplete) ...[
            const SizedBox(height: 16),
            Text(
              widget.quest.frequency == QuestFrequency.daily
                  ? "Vous avez déjà validé aujourd'hui."
                  : 'Vous avez déjà validé cette semaine.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ] else if (!_loadingHistory && widget.quest.targetPerPeriod > 1) ...[
            const SizedBox(height: 16),
            Text(
              '$_currentPeriodCount/${widget.quest.targetPerPeriod} '
              '${widget.quest.frequency == QuestFrequency.daily ? "aujourd'hui" : 'cette semaine'}',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
          ],
          const SizedBox(height: 40),
          Text(
            'PREUVE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _EvidenceCard(
                    icon: Icons.photo_camera,
                    label: 'PHOTO',
                    selected: _evidenceType == _EvidenceType.photo,
                    onTap: () => setState(() {
                      _evidenceType = _EvidenceType.photo;
                      _pickedVideo = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EvidenceCard(
                    icon: Icons.videocam,
                    label: 'VIDÉO',
                    selected: _evidenceType == _EvidenceType.video,
                    onTap: () => setState(() {
                      _evidenceType = _EvidenceType.video;
                      _pickedPhotos.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EvidenceCard(
                    icon: Icons.text_snippet,
                    label: 'TEXTE',
                    selected: _evidenceType == _EvidenceType.text,
                    onTap: () => setState(() {
                      _evidenceType = _EvidenceType.text;
                      _pickedVideo = null;
                      _pickedPhotos.clear();
                    }),
                  ),
                ),
              ],
            ),
          ),
          if (_evidenceType == _EvidenceType.photo) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _pickedPhotos.length; i++)
                  _PhotoThumbnail(photo: _pickedPhotos[i], onRemove: () => _removePhoto(i)),
                if (_pickedPhotos.length < _maxPhotos)
                  _AddPhotoTile(onTap: _pickPhoto),
              ],
            ),
          ] else if (_evidenceType == _EvidenceType.video) ...[
            const SizedBox(height: 16),
            if (_pickedVideo == null)
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.upload, color: AppColors.primary),
                label: Text(
                  'Choisir un fichier',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                ),
              )
            else
              _VideoSelectedCard(
                video: _pickedVideo!,
                onRemove: () => setState(() => _pickedVideo = null),
              ),
          ],
          const SizedBox(height: 32),
          Text(
            _evidenceType == _EvidenceType.text ? 'VOTRE PREUVE' : 'RÉCIT DE PERFORMANCE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              hintText: _evidenceType == _EvidenceType.text
                  ? 'Décrivez ce que vous avez accompli...'
                  : 'Décrivez votre exécution ici (optionnel)...',
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
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ],
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
            onPressed: disabled ? null : _submit,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            Icon(icon, color: selected ? AppColors.primary : AppColors.outline, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected ? AppColors.primary : AppColors.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _thumbnailSize = 88.0;

/// A locally-picked photo, shown before upload — actual bytes, not a
/// filename or remote URL, with a remove button in the corner.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove});

  final PickedEvidence photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _thumbnailSize,
      height: _thumbnailSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadii.interactiveRadius,
            child: Image.memory(
              photo.bytes,
              width: _thumbnailSize,
              height: _thumbnailSize,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _thumbnailSize,
        height: _thumbnailSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.outlineVariant15),
        ),
        child: const Icon(Icons.add, color: AppColors.primary),
      ),
    );
  }
}

/// A locally-picked video, shown before upload. No real thumbnail frame
/// (would require a native thumbnail-generation dependency) — an icon card
/// with the filename stands in as the "selected" visual instead of a bare
/// filename text.
class _VideoSelectedCard extends StatelessWidget {
  const _VideoSelectedCard({required this.video, required this.onRemove});

  final PickedEvidence video;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              video.filename,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: AppColors.outline, size: 20),
          ),
        ],
      ),
    );
  }
}
