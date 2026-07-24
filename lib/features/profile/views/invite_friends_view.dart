import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';
import '../../social/models/ally_request.dart';
import '../../social/models/user_search_result.dart';

/// "Alliés" hub — share a real invite link, invite by email (auto-linked on
/// signup, see PendingInviteService/DeepLinkService), redeem a pasted
/// invitation code, search for users to send a direct ally request, and
/// respond to incoming requests.
class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({super.key});

  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  final _sentRequestIds = <String>{};

  late final AlliesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AlliesController>();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createAndCopyLink() async {
    await _controller.createInvitation();
    final invitation = _controller.lastCreatedInvitation.value;
    if (invitation == null || invitation.deepLink == null) return;
    await Clipboard.setData(ClipboardData(text: invitation.deepLink!));
    if (!mounted) return;
    _showSnack('Lien copié.');
  }

  Future<void> _sendByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await _controller.createInvitation(inviteeContact: email);
    if (!mounted) return;
    if (_controller.errorMessage.value != null) {
      _showSnack(_controller.errorMessage.value!);
      return;
    }
    _emailController.clear();
    _showSnack('Invitation envoyée par email.');
  }

  void _redeemCode() {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;
    // Accept either a bare token or a full pasted `axiom://invite/<token>`
    // link (e.g. from "Lien copié.") — extract the token in the latter case.
    final token = Uri.tryParse(input) != null
        ? extractInviteToken(Uri.parse(input)) ?? input
        : input;
    Get.toNamed(AppRoutes.invitationAlly, arguments: token);
  }

  Future<void> _sendRequest(UserSearchResult user) async {
    await _controller.sendRequest(user.id);
    if (!mounted) return;
    if (_controller.errorMessage.value != null) {
      _showSnack(_controller.errorMessage.value!);
      return;
    }
    setState(() => _sentRequestIds.add(user.id));
    _showSnack('Demande envoyée à ${user.firstName}.');
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
                    'EXPANSION DU RÉSEAU',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invitez des alliés.',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 40,
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
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 12),
                        for (final ally in allies) ...[
                          _AllyRow(ally: ally),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.structuralRadius,
                      border: Border.all(color: AppColors.outlineVariant15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PARTAGER UN LIEN',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: "GÉNÉRER ET COPIER UN LIEN D'INVITATION",
                          leadingIcon: Icons.link,
                          onPressed: _createAndCopyLink,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'INVITER PAR EMAIL',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                                decoration: InputDecoration(
                                  hintText: 'email@exemple.com',
                                  hintStyle:
                                      AppTypography.bodyMd.copyWith(color: AppColors.outline),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLowest,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                    borderSide: BorderSide(color: AppColors.outlineVariant15),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                    borderSide: BorderSide(color: AppColors.outlineVariant15),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primaryFixedDim),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _sendByEmail,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppColors.outline,
                                  side: BorderSide(color: AppColors.outline20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                  ),
                                ),
                                child: const Icon(Icons.send, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                  hintText: 'Coller le code ici',
                                  hintStyle:
                                      AppTypography.bodyMd.copyWith(color: AppColors.outline),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLowest,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                    borderSide: BorderSide(color: AppColors.outlineVariant15),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                    borderSide: BorderSide(color: AppColors.outlineVariant15),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primaryFixedDim),
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
                  const SizedBox(height: 32),
                  Text(
                    'RECHERCHER UN ALLIÉ',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _controller.search,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, email ou téléphone...',
                      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                      prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.structuralRadius,
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadii.structuralRadius,
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.primaryFixedDim),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final error = _controller.errorMessage.value;
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        error,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Obx(() {
                    final allyIds = _controller.allies.map((a) => a.id).toSet();
                    final results = _controller.searchResults
                        .where((u) => !allyIds.contains(u.id))
                        .toList();
                    if (results.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        for (final user in results) ...[
                          _SearchResultRow(
                            user: user,
                            requested: _sentRequestIds.contains(user.id),
                            onInvite: () => _sendRequest(user),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }),
                  const SizedBox(height: 32),
                  Obx(() {
                    final incoming = _controller.incomingRequests;
                    if (incoming.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMANDES REÇUES',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 12),
                        for (final request in incoming) ...[
                          _IncomingRequestRow(
                            request: request,
                            onAccept: () => _controller.respondToRequest(request.id, accept: true),
                            onDecline: () =>
                                _controller.respondToRequest(request.id, accept: false),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }),
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
  const _AllyRow({required this.ally});

  final Ally ally;

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
              const Icon(Icons.check_circle, size: 16, color: AppColors.emerald),
              const SizedBox(width: 4),
              Text(
                'ALLIÉ',
                style: AppTypography.labelMd.copyWith(color: AppColors.emerald, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.user,
    required this.requested,
    required this.onInvite,
  });

  final UserSearchResult user;
  final bool requested;
  final VoidCallback onInvite;

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
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${user.firstName} ${user.lastName}',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: requested ? null : onInvite,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: requested ? AppColors.outline : AppColors.primaryFixedDim,
              side: BorderSide(
                color: requested ? AppColors.outlineVariant : AppColors.primaryFixedDim,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
            ),
            child: Text(
              requested ? 'ENVOYÉ' : 'INVITER',
              style: AppTypography.labelMd.copyWith(fontSize: 10),
            ),
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
            icon: const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
          ),
        ],
      ),
    );
  }
}
