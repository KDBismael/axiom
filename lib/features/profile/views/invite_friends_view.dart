import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';
import '../../social/models/ally_request.dart';
import '../widgets/invite_friends_sheet.dart';

/// "Gérer mes alliés" — the existing-allies list, sent/received requests,
/// and code redemption. Recruiting a *new* ally (search, invite link,
/// share) lives in [InviteFriendsSheet] instead, matching the mockup's
/// `sheetInvite` bottom sheet exactly; this page has no mockup counterpart,
/// so it keeps the app's own established card/list style.
class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({super.key});

  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  final _codeController = TextEditingController();
  late final AlliesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AlliesController>();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _redeemCode() {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;
    // Accept either a bare token or a full pasted `axiom://invite/<token>`
    // link (e.g. from the invite sheet's "Copié") — extract the token in
    // the latter case.
    final token = Uri.tryParse(input) != null
        ? extractInviteToken(Uri.parse(input)) ?? input
        : input;
    Get.toNamed(AppRoutes.invitationAlly, arguments: token);
  }

  Future<void> _removeAlly(Ally ally) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet allié ?'),
        content: Text(
          '${ally.firstName} ${ally.lastName} ne fera plus partie de vos alliés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('RETIRER'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await _controller.removeAlly(ally.id);
    if (!mounted) return;
    if (!removed) {
      _showSnack(
        _controller.errorMessage.value ?? 'Impossible de retirer cet allié.',
      );
      return;
    }
    _showSnack('${ally.firstName} a été retiré de vos alliés.');
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RÉSEAU',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérer mes alliés.',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showAppBottomSheet(
                        context,
                        builder: (_) => const InviteFriendsSheet(),
                      ),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('INVITER UN NOUVEL ALLIÉ'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.volt,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.interactiveRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(() {
                    final allies = _controller.allies;
                    if (allies.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MES ALLIÉS (${allies.length})',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final ally in allies) ...[
                          _AllyRow(ally: ally, onRemove: () => _removeAlly(ally)),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                  Obx(() {
                    final incoming = _controller.incomingRequests;
                    if (incoming.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMANDES REÇUES',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final request in incoming) ...[
                          _IncomingRequestRow(
                            request: request,
                            onAccept: () => _controller.respondToRequest(
                              request.id,
                              accept: true,
                            ),
                            onDecline: () => _controller.respondToRequest(
                              request.id,
                              accept: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                  Obx(() {
                    final outgoing = _controller.outgoingRequests;
                    if (outgoing.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMANDES EN ATTENTE',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final request in outgoing) ...[
                          _PendingRequestRow(request: request),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                  Text(
                    'CODE D\'INVITATION REÇU',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                          decoration: InputDecoration(
                            hintText: 'Coller le lien ou le code ici',
                            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.interactiveRadius,
                              borderSide: BorderSide(color: AppColors.outlineVariant15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadii.interactiveRadius,
                              borderSide: BorderSide(color: AppColors.outlineVariant15),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.volt),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _redeemCode,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.outline,
                            side: BorderSide(color: AppColors.outline20),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.interactiveRadius,
                            ),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllyRow extends StatelessWidget {
  const _AllyRow({required this.ally, required this.onRemove});

  final Ally ally;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceBright,
            child: Text(
              ally.firstName.isNotEmpty ? ally.firstName[0].toUpperCase() : '?',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${ally.firstName} ${ally.lastName}',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.volt),
              const SizedBox(width: 4),
              Text(
                'ALLIÉ',
                style: AppTypography.labelMd.copyWith(color: AppColors.volt, fontSize: 10),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Retirer cet allié',
            onPressed: onRemove,
            icon: const Icon(Icons.person_remove_outlined, color: AppColors.outline, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestRow extends StatelessWidget {
  const _PendingRequestRow({required this.request});

  final AllyRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceBright,
            child: Text(
              request.otherUser.firstName.isNotEmpty
                  ? request.otherUser.firstName[0].toUpperCase()
                  : '?',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${request.otherUser.firstName} ${request.otherUser.lastName}',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          Text(
            'EN ATTENTE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestRow extends StatelessWidget {
  const _IncomingRequestRow({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final AllyRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceBright,
            child: Text(
              request.otherUser.firstName.isNotEmpty
                  ? request.otherUser.firstName[0].toUpperCase()
                  : '?',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${request.otherUser.firstName} ${request.otherUser.lastName}',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.close, color: AppColors.outline, size: 20),
          ),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle, color: AppColors.volt, size: 20),
          ),
        ],
      ),
    );
  }
}
