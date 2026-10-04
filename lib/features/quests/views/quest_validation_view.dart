import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/borders/dashed_rrect_painter.dart';
import '../../rank/controllers/rank_controller.dart';
import '../controllers/focus_timer_controller.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/quest_model.dart';
import '../repositories/quest_repository.dart';
import '../services/evidence_picker_service.dart';
import '../services/focus_session_draft_store.dart';
import '../utils/period_progress.dart';
import '../utils/check_in_availability.dart';

class QuestValidationView extends GetView<QuestListController> {
  const QuestValidationView({super.key});

  @override
  Widget build(BuildContext context) {
    final String questId = Get.arguments as String;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final quest = controller.findById(questId);
          if (quest == null) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Quête introuvable.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _ValidationBody(quest: quest);
        }),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Text(
          '←',
          style: TextStyle(fontSize: 18, color: AppColors.primary),
        ),
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
  FocusSessionDraft? _focusDraft;

  bool get _periodComplete =>
      _currentPeriodCount >= widget.quest.targetPerPeriod;
  bool get _deadlinePassed =>
      checkInAvailability(widget.quest, const [], DateTime.now()) ==
      CheckInAvailability.deadlinePassed;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadFocusDraft();
  }

  Future<void> _loadHistory() async {
    final checkIns = await Get.find<QuestListController>().fetchCheckIns(
      widget.quest.id,
    );
    final count = countCheckInsInCurrentPeriod(
      checkIns,
      widget.quest.frequency,
      DateTime.now(),
      startDate: widget.quest.startDate,
    );
    if (!mounted) return;
    setState(() {
      _loadingHistory = false;
      _currentPeriodCount = count;
    });
  }

  /// A focus-timer session finished but not yet submitted rides along on
  /// this check-in — see `FocusTimerController.finish()` and
  /// `FocusSessionDraftStore`.
  Future<void> _loadFocusDraft() async {
    final draft = await Get.find<FocusSessionDraftStore>().read(
      widget.quest.id,
    );
    if (!mounted || draft == null) return;
    setState(() => _focusDraft = draft);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoFromCamera() async {
    if (_pickedPhotos.length >= _maxPhotos) return;
    final service = Get.find<EvidencePickerService>();
    try {
      final picked = await service.pickPhoto(ImageSource.camera);
      if (picked == null || !mounted) return;
      setState(() => _pickedPhotos.add(picked));
    } on EvidencePickerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible d’accéder à la caméra.');
    }
  }

  Future<void> _pickPhotosFromGallery() async {
    final remaining = _maxPhotos - _pickedPhotos.length;
    if (remaining <= 0) return;
    final service = Get.find<EvidencePickerService>();
    try {
      final picked = await service.pickMultiPhotos(limit: remaining);
      if (picked.isEmpty || !mounted) return;
      setState(() => _pickedPhotos.addAll(picked));
    } on EvidencePickerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible d’accéder à la galerie.');
      }
    }
  }

  Future<void> _pickVideoFrom(ImageSource source) async {
    final service = Get.find<EvidencePickerService>();
    try {
      final picked = await service.pickVideo(source);
      if (picked == null || !mounted) return;
      setState(() => _pickedVideo = picked);
    } on EvidencePickerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Impossible d’accéder à la caméra ou à la galerie.',
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    final hasProof = _evidenceType == _EvidenceType.video
        ? _pickedVideo != null
        : _pickedPhotos.isNotEmpty;
    if (widget.quest.requiresProof &&
        _evidenceType != _EvidenceType.text &&
        !hasProof) {
      setState(() => _error = 'Une preuve est requise pour cette quête.');
      return;
    }
    if (_evidenceType == _EvidenceType.text &&
        _descriptionController.text.trim().isEmpty) {
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
      } else if (_evidenceType == _EvidenceType.photo &&
          _pickedPhotos.isNotEmpty) {
        fileIds = [
          for (final photo in _pickedPhotos)
            await controller.uploadEvidenceFile(photo),
        ];
      }

      final proofType = switch (_evidenceType) {
        _EvidenceType.photo => ProofType.photo,
        _EvidenceType.video => ProofType.video,
        _EvidenceType.text => ProofType.text,
      };

      final result = await controller.checkIn(
        widget.quest.id,
        proofType:
            (fileId != null ||
                fileIds != null ||
                _evidenceType == _EvidenceType.text)
            ? proofType
            : null,
        fileId: fileId,
        fileIds: fileIds,
        textContent: _evidenceType == _EvidenceType.text
            ? _descriptionController.text.trim()
            : null,
        description:
            _evidenceType != _EvidenceType.text &&
                _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        focusStartedAt: _focusDraft?.startedAt,
        focusEndedAt: _focusDraft?.endedAt,
      );

      if (!mounted) return;
      if (controller.errorMessage.value != null || result == null) {
        setState(() => _error = controller.errorMessage.value);
        return;
      }

      if (_focusDraft != null) {
        await Get.find<FocusSessionDraftStore>().clear(widget.quest.id);
        // The timer controller is kept alive (tagged + permanent) across
        // navigation so the session survives leaving the timer screen —
        // now that it's actually been submitted, free it for real.
        if (Get.isRegistered<FocusTimerController>(tag: widget.quest.id)) {
          Get.delete<FocusTimerController>(tag: widget.quest.id, force: true);
        }
      }

      // A crossed streak milestone is awarded synchronously by the backend
      // check-in endpoint, so the rank snapshot may already be stale by the
      // time the Celebration screen renders it — refresh it now rather than
      // waiting for the next scheduled reload.
      unawaited(Get.find<RankController>().loadAll());

      Get.offNamed(
        AppRoutes.questCheckinStatus,
        arguments: {
          'questId': widget.quest.id,
          'requiresProof': widget.quest.requiresProof,
          'result': result,
        },
      );
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

  String? get _validatorMessage {
    final names = widget.quest.allies
        .where((a) => a.status == QuestAllyStatus.accepted)
        .map((a) => a.firstName.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return null;
    if (names.length == 1) return '${names.first} validera ta preuve.';
    return '${names.join(' ou ')} validera ta preuve. Le premier à décider l\'emporte.';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_submitting &&
        !_loadingHistory &&
        !_periodComplete &&
        !_deadlinePassed;
    final validatorMessage = _validatorMessage;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VALIDER AVEC PREUVE',
                      style: TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 11,
                        letterSpacing: 0.14 * 11,
                        color: AppColors.outlineMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.quest.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_focusDraft != null) ...[
                  Text(
                    'Session de focus : '
                    '${_focusDraft!.endedAt.difference(_focusDraft!.startedAt).inMinutes} min',
                    style: const TextStyle(fontSize: 13, color: AppColors.volt),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_deadlinePassed) ...[
                  const Text(
                    'Le délai de validation de cette quête est dépassé.',
                    style: TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                ] else if (!_loadingHistory && _periodComplete) ...[
                  Text(
                    widget.quest.frequency == QuestFrequency.daily
                        ? "Vous avez déjà validé aujourd'hui."
                        : 'Vous avez déjà validé cette semaine.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (!_loadingHistory &&
                    widget.quest.targetPerPeriod > 1) ...[
                  Text(
                    '$_currentPeriodCount/${widget.quest.targetPerPeriod} '
                    '${widget.quest.frequency == QuestFrequency.daily ? "aujourd'hui" : 'cette semaine'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _EvidenceTypeSegmented(
                  value: _evidenceType,
                  onChanged: (type) => setState(() {
                    _evidenceType = type;
                    if (type != _EvidenceType.photo) _pickedPhotos.clear();
                    if (type != _EvidenceType.video) _pickedVideo = null;
                  }),
                ),
                if (_evidenceType == _EvidenceType.photo) ...[
                  const SizedBox(height: 16),
                  _PhotoSlotsGrid(
                    photos: _pickedPhotos,
                    onRemove: _removePhoto,
                    onAddTap: _pickPhotosFromGallery,
                  ),
                  const SizedBox(height: 8),
                  _PickerButtonsRow(
                    primaryLabel: 'Appareil photo',
                    onPrimary: _pickedPhotos.length >= _maxPhotos
                        ? null
                        : _pickPhotoFromCamera,
                    onGallery: _pickedPhotos.length >= _maxPhotos
                        ? null
                        : _pickPhotosFromGallery,
                  ),
                ] else if (_evidenceType == _EvidenceType.video) ...[
                  const SizedBox(height: 16),
                  if (_pickedVideo == null)
                    _PickerButtonsRow(
                      primaryLabel: 'Caméra',
                      onPrimary: () => _pickVideoFrom(ImageSource.camera),
                      onGallery: () => _pickVideoFrom(ImageSource.gallery),
                    )
                  else
                    _VideoSelectedCard(
                      video: _pickedVideo!,
                      onRemove: () => setState(() => _pickedVideo = null),
                    ),
                ],
                const SizedBox(height: 16),
                _CommentField(
                  label: _evidenceType == _EvidenceType.text
                      ? 'VOTRE PREUVE'
                      : 'COMMENTAIRE (OPTIONNEL)',
                  hint: _evidenceType == _EvidenceType.text
                      ? 'Décrivez ce que vous avez accompli...'
                      : 'Ex. 5,3 km, parc de Hann',
                  controller: _descriptionController,
                  singleLine: _evidenceType != _EvidenceType.text,
                ),
                if (validatorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ValidatorInfoBanner(text: validatorMessage),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1E1E23))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: AppPressable(
              color: canSubmit
                  ? AppColors.volt
                  : AppColors.surfaceContainerHighest,
              shadowColor: canSubmit
                  ? AppColors.voltShadow
                  : const Color(0xFF0A0A0C),
              shadowThickness: 5,
              borderRadius: BorderRadius.circular(16),
              enabled: canSubmit,
              onTap: _submit,
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        'ENVOYER LA PREUVE',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.06 * 14,
                          color: canSubmit
                              ? AppColors.onPrimary
                              : AppColors.outlineFaint,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceTypeSegmented extends StatelessWidget {
  const _EvidenceTypeSegmented({required this.value, required this.onChanged});

  final _EvidenceType value;
  final ValueChanged<_EvidenceType> onChanged;

  static const _options = [
    (_EvidenceType.photo, 'Photo'),
    (_EvidenceType.video, 'Vidéo'),
    (_EvidenceType.text, 'Texte'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (type, label) in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == type
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: value == type
                          ? AppColors.onPrimary
                          : AppColors.outline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoSlotsGrid extends StatelessWidget {
  const _PhotoSlotsGrid({
    required this.photos,
    required this.onRemove,
    required this.onAddTap,
  });

  final List<PickedEvidence> photos;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _maxPhotos; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: i < photos.length
                  ? _PhotoSlotFilled(
                      photo: photos[i],
                      onRemove: () => onRemove(i),
                    )
                  : _PhotoSlotEmpty(onTap: onAddTap),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoSlotFilled extends StatelessWidget {
  const _PhotoSlotFilled({required this.photo, required this.onRemove});

  final PickedEvidence photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A4A1C)),
            image: DecorationImage(
              image: MemoryImage(photo.bytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoSlotEmpty extends StatelessWidget {
  const _PhotoSlotEmpty({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const CustomPaint(
        painter: DashedRRectPainter(color: AppColors.surfaceBright, radius: 14),
        child: Center(
          child: Text(
            '+',
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 20,
              color: AppColors.outlineFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerButtonsRow extends StatelessWidget {
  const _PickerButtonsRow({
    required this.primaryLabel,
    required this.onPrimary,
    required this.onGallery,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PickerButton(label: primaryLabel, onTap: onPrimary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PickerButton(label: 'Galerie', onTap: onGallery),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.surfaceBright),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.singleLine,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      maxLines: singleLine ? null : 5,
      minLines: singleLine ? null : 5,
      expands: singleLine,
      textAlignVertical: singleLine ? TextAlignVertical.center : null,
      style: const TextStyle(fontSize: 15, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.outlineFaint),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: singleLine
            ? const EdgeInsets.symmetric(horizontal: 16)
            : const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.volt),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 11,
            letterSpacing: 0.14 * 11,
            color: AppColors.outlineMuted,
          ),
        ),
        const SizedBox(height: 8),
        singleLine ? SizedBox(height: 52, child: field) : field,
      ],
    );
  }
}

class _ValidatorInfoBanner extends StatelessWidget {
  const _ValidatorInfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17142A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2650)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Transform.rotate(
              angle: 0.7853981633974483,
              child: Container(width: 8, height: 8, color: AppColors.violet),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFC6BEF5),
              ),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.surfaceBright),
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
