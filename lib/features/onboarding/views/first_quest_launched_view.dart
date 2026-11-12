import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../payments/services/url_opener.dart';
import '../controllers/guided_tour_controller.dart';

/// Guided tour step 2: the first quest is live — now invite an ally.
/// Inviting is encouraged but skippable ("Plus tard").
class FirstQuestLaunchedView extends StatefulWidget {
  const FirstQuestLaunchedView({super.key});

  @override
  State<FirstQuestLaunchedView> createState() => _FirstQuestLaunchedViewState();
}

class _FirstQuestLaunchedViewState extends State<FirstQuestLaunchedView> {
  final _tour = Get.find<GuidedTourController>();
  bool _sharing = false;

  Future<void> _invite() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final message = await _tour.prepareInviteMessage();
      if (!mounted) return;
      if (message == null) {
        Get.snackbar(
          'Invitation impossible',
          _tour.errorMessage.value ?? 'Réessaie dans un instant.',
        );
        return;
      }
      final opener = Get.isRegistered<UrlOpener>()
          ? Get.find<UrlOpener>()
          : UrlOpener();
      var opened = false;
      try {
        opened = await opener.open(
          'https://wa.me/?text=${Uri.encodeComponent(message)}',
        );
      } catch (_) {}
      if (!opened) {
        final result = await SharePlus.instance.share(
          ShareParams(text: message),
        );
        if (result.status != ShareResultStatus.success) return;
      }
      // Opening a share target is not a delivery receipt.
      _tour.markInviteShared();
    } catch (_) {
      if (mounted) {
        Get.snackbar(
          'Partage indisponible',
          'Réessaie ou continue sans invitation pour le moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _continue() {
    Get.back();
    _tour.continueToCheckIn();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _tour.continueToCheckIn();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QUÊTE LANCÉE',
                  style: AppTypography.labelMd.copyWith(color: AppColors.volt),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Text(
                    _tour.launchedQuest.value?.title ?? 'Ta quête',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 26,
                      height: 1.15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elle commence aujourd\'hui. Chaque validation fait grandir '
                  'ta série.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.structuralRadius,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Obx(
                    () => _tour.inviteShared.value
                        ? const _InviteShared()
                        : const _InvitePitch(),
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final shared = _tour.inviteShared.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: shared ? 'CONTINUER' : 'INVITER SUR WHATSAPP',
                        loading: _sharing,
                        onPressed: shared ? _continue : _invite,
                      ),
                      if (!shared)
                        TextButton(
                          onPressed: _sharing ? null : _continue,
                          child: Text(
                            'Plus tard',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outlineMuted,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitePitch extends StatelessWidget {
  const _InvitePitch();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÉTAPE 2/3',
          style: AppTypography.labelMd.copyWith(
            fontSize: 10.5,
            color: AppColors.volt,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Invite un allié qui t'encourage",
          style: AppTypography.headlineMd.copyWith(
            fontSize: 17,
            height: 1.25,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Un allié voit tes progrès, valide tes preuves et te relance '
          'quand tu décroches. À deux, on lâche moins facilement.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

class _InviteShared extends StatelessWidget {
  const _InviteShared();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✓ LIEN PRÊT À PARTAGER',
          style: AppTypography.labelMd.copyWith(color: AppColors.volt),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dès que ton allié accepte le lien, vous serez connectés et tu '
          'pourras l\'ajouter à tes quêtes. Tu seras notifié.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}
