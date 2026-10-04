import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/avatar_colors.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally_invitation.dart';
import '../../social/models/ally_request.dart';
import '../../social/models/user_search_result.dart';

/// The mockup's `sheetInvite` bottom sheet, verbatim — search for an
/// existing ally, or share your invitation link. Opened via
/// `showAppBottomSheet` from Profile's "Inviter des amis" row.
///
/// The mockup's "+50 pts par ami" / "vous gagnez tous les deux 50 points de
/// rang" copy is a real backend mechanic (GamificationService.
/// awardReferralBonus): +50 to both people once the invitee actually
/// registers via this invitation — additive on top of the invitee's own
/// +15 for accepting it.
class InviteFriendsSheet extends StatefulWidget {
  const InviteFriendsSheet({super.key});

  @override
  State<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends State<InviteFriendsSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _codeController = TextEditingController();
  late final AlliesController _controller;
  bool _generating = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AlliesController>();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _redeemCode() {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;
    // Accept either a bare token or a full pasted `axiom://invite/<token>`
    // link (e.g. from this sheet's own "Copié" above) — extract the token
    // in the latter case.
    final token = Uri.tryParse(input) != null
        ? extractInviteToken(Uri.parse(input)) ?? input
        : input;
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.invitationAlly, arguments: token);
  }

  Future<void> _generateLink() async {
    setState(() => _generating = true);
    await _controller.createInvitation();
    if (!mounted) return;
    setState(() => _generating = false);
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '+50 PTS PAR AMI',
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 11,
                letterSpacing: 0.14 * 11,
                color: AppColors.volt,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Recrute tes alliés',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: AppRadii.interactiveRadius,
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.volt
                      : AppColors.outlineVariantStrong,
                ),
                color: const Color(0xFF0F0F12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.outlineMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _controller.search,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Chercher un ami déjà sur Ndeli',
                        hintStyle: TextStyle(color: AppColors.outlineMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final query = _controller.searchQuery.value;
              if (query.trim().length < 2) return const SizedBox.shrink();
              final allyIds = _controller.allies.map((a) => a.id).toSet();
              final requestsByUser = {
                for (final request in _controller.allyRequests)
                  request.otherUser.id: request,
              };
              final results = _controller.searchResults
                  .where((u) => !allyIds.contains(u.id))
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: results.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: AppColors.outlineVariantStrong,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Text(
                          'Personne de ce nom sur Ndeli. Invite-le avec ton lien.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.outlineMuted,
                          ),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 196),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final user in results) ...[
                                _SearchResultRow(
                                  user: user,
                                  request: requestsByUser[user.id],
                                  onInvite: () =>
                                      _controller.sendRequest(user.id),
                                  onAccept: (request) =>
                                      _controller.respondToRequest(
                                        request.id,
                                        accept: true,
                                      ),
                                  onDecline: (request) =>
                                      _controller.respondToRequest(
                                        request.id,
                                        accept: false,
                                      ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ],
                          ),
                        ),
                      ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFF26262C))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'PAS ENCORE INSCRIT ?',
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 11,
                      letterSpacing: 0.14 * 11,
                      color: AppColors.outlineFaint,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFF26262C))),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Partage ton lien. Quand un ami s'inscrit, vous gagnez tous "
              'les deux 50 points de rang.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final invitation = _controller.lastCreatedInvitation.value;
              final link = invitation?.deepLink;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.interactiveRadius,
                  color: const Color(0xFF0F0F12),
                  border: Border.all(
                    color: const Color(0xFF3A4A1C),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link ?? 'Génère ton lien pour le partager',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: link != null ? 'Unbounded' : 'Geist',
                          fontWeight: link != null
                              ? FontWeight.w800
                              : FontWeight.w400,
                          fontSize: link != null ? 15 : 14,
                          color: link != null
                              ? AppColors.volt
                              : AppColors.outlineMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: AppPressable(
                        color: _copied ? AppColors.surfaceContainerHighest : AppColors.volt,
                        shadowColor: _copied
                            ? AppColors.surfaceBright
                            : AppColors.voltShadow,
                        shadowThickness: 3,
                        enabled: !_generating,
                        onTap: link == null ? _generateLink : () => _copyLink(link),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: Text(
                              _generating
                                  ? '…'
                                  : link == null
                                  ? 'GÉNÉRER'
                                  : (_copied ? 'COPIÉ' : 'COPIER'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final recruited = _controller.invitations
                  .where((i) => i.status == InvitationStatus.accepted)
                  .length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2210),
                  borderRadius: AppRadii.interactiveRadius,
                  border: Border.all(color: const Color(0xFF2F3F14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amis recrutés',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFFC9DDA0),
                      ),
                    ),
                    Text(
                      '$recruited',
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w700,
                        color: AppColors.volt,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Text(
              "CODE D'INVITATION REÇU",
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 11,
                letterSpacing: 0.14 * 11,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: 'Coller le lien ou le code ici',
                      hintStyle: const TextStyle(color: AppColors.outlineMuted),
                      filled: true,
                      fillColor: const Color(0xFF0F0F12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.interactiveRadius,
                        borderSide: BorderSide(color: AppColors.outlineVariantStrong),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadii.interactiveRadius,
                        borderSide: BorderSide(color: AppColors.outlineVariantStrong),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: AppColors.volt),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _redeemCode,
                  borderRadius: AppRadii.interactiveRadius,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.interactiveRadius,
                      border: Border.all(color: AppColors.outline20),
                    ),
                    child: const Icon(Icons.arrow_forward, size: 18, color: AppColors.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontSize: 14, color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.user,
    required this.request,
    required this.onInvite,
    required this.onAccept,
    required this.onDecline,
  });

  final UserSearchResult user;
  final AllyRequest? request;
  final VoidCallback onInvite;
  final ValueChanged<AllyRequest> onAccept;
  final ValueChanged<AllyRequest> onDecline;

  @override
  Widget build(BuildContext context) {
    final incoming = request?.direction == AllyRequestDirection.incoming;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColorForId(user.id),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initialsFor(user.firstName, user.lastName),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Sur Ndeli',
                  style: TextStyle(fontSize: 12, color: AppColors.outlineMuted),
                ),
              ],
            ),
          ),
          if (incoming) ...[
            IconButton(
              tooltip: 'Refuser',
              onPressed: () => onDecline(request!),
              icon: const Icon(
                Icons.close,
                color: AppColors.outlineMuted,
                size: 18,
              ),
            ),
            IconButton(
              tooltip: 'Accepter',
              onPressed: () => onAccept(request!),
              icon: const Icon(
                Icons.check_circle,
                color: AppColors.volt,
                size: 20,
              ),
            ),
          ] else
            InkWell(
              onTap: request == null ? onInvite : null,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: request != null ? AppColors.outlineVariant : AppColors.volt,
                  ),
                ),
                child: Text(
                  request != null ? 'EN ATTENTE' : 'INVITER',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: request != null ? AppColors.outlineMuted : AppColors.volt,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
