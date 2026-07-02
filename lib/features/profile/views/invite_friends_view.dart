import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';

class _Contact {
  final String name;
  final String initials;

  const _Contact(this.name, this.initials);
}

const _mockContacts = [
  _Contact('Julian Donahue', 'JD'),
  _Contact('Marcus Reeves', 'MR'),
  _Contact('Sarah Miller', 'SM'),
  _Contact('Alex Lindon', 'AL'),
  _Contact('Tanya Chen', 'TC'),
];

const _mockInviteLink = 'https://axiom.app/invite/JMV-4821';

class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({super.key});

  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  final _invitedNames = <String>{};
  String _query = '';

  @override
  void dispose() {
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

  void _sendEmailInvite() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    _showSnack('Invitation envoyée à $email.');
    _emailController.clear();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: _mockInviteLink));
    _showSnack('Lien copié.');
  }

  void _invite(String name) {
    setState(() => _invitedNames.add(name));
    _showSnack('Invitation envoyée à $name.');
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _mockContacts
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: GlassChrome(
              safeAreaTop: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                    Text(
                      'AXIOM',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 20,
                      ),
                    ),
                    const Spacer(),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      child: Icon(Icons.person, size: 18, color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPANSION DU RÉSEAU',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invitez des amis.',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                          'INVITER PAR EMAIL',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                          decoration: InputDecoration(
                            hintText: 'adresse@email.com',
                            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                            prefixIcon: const Icon(
                              Icons.mail_outline,
                              color: AppColors.outline,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.interactiveRadius,
                              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadii.interactiveRadius,
                              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: AppColors.primaryFixedDim),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: "ENVOYER L'INVITATION",
                                onPressed: _sendEmailInvite,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _copyLink,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppColors.outline,
                                  side: BorderSide(color: AppColors.outline20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.interactiveRadius,
                                  ),
                                ),
                                child: const Icon(Icons.content_copy, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou téléphone...',
                      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                      prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                        borderSide: BorderSide(color: AppColors.primaryFixedDim),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Aucun contact trouvé.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                        ),
                      ),
                    )
                  else
                    for (final contact in contacts) ...[
                      _ContactRow(
                        contact: contact,
                        invited: _invitedNames.contains(contact.name),
                        onInvite: () => _invite(contact.name),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: _copyLink,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, color: AppColors.outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'INVITER VIA UN LIEN',
                            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ),
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.invited,
    required this.onInvite,
  });

  final _Contact contact;
  final bool invited;
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
              contact.initials,
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              contact.name,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: invited ? null : onInvite,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: invited ? AppColors.outline : AppColors.primaryFixedDim,
              side: BorderSide(
                color: invited ? AppColors.outlineVariant : AppColors.primaryFixedDim,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
            ),
            child: Text(
              invited ? 'INVITÉ' : 'INVITER',
              style: AppTypography.labelMd.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
