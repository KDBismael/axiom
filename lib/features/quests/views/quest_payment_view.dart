import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../controllers/quest_create_controller.dart';

class _ProviderInfo {
  final MobileMoneyProvider provider;
  final String label;
  final String subtitle;
  final String initials;
  final Color color;

  const _ProviderInfo({
    required this.provider,
    required this.label,
    required this.subtitle,
    required this.initials,
    required this.color,
  });
}

const _providers = [
  _ProviderInfo(
    provider: MobileMoneyProvider.orangeMoney,
    label: 'Orange Money',
    subtitle: "OM CÔTE D'IVOIRE",
    initials: 'OM',
    color: Color(0xFFFF7900),
  ),
  _ProviderInfo(
    provider: MobileMoneyProvider.mtnMoney,
    label: 'MTN Money',
    subtitle: 'MOMO INTERNATIONAL',
    initials: 'MTN',
    color: Color(0xFFFFCC00),
  ),
  _ProviderInfo(
    provider: MobileMoneyProvider.moovMoney,
    label: 'Moov Money',
    subtitle: 'MOOV AFRICA',
    initials: 'MV',
    color: Color(0xFF0055A4),
  ),
  _ProviderInfo(
    provider: MobileMoneyProvider.wave,
    label: 'Wave',
    subtitle: 'ZÉRO FRAIS',
    initials: 'W',
    color: Color(0xFF1DB9EC),
  ),
];

/// Mobile money checkout — the terminal step of the staked-quest wizard
/// flow. No real payment processor is wired up yet (mock data now,
/// backend later); confirming finalizes quest creation directly and
/// returns to the dashboard.
class QuestPaymentView extends GetView<QuestCreateController> {
  const QuestPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: AppColors.primary, size: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Obx(() {
                final amount = double.tryParse(controller.stakeText.value) ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECKOUT PROCESS',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PAIEMENT SÉCURISÉ',
                      style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppRadii.structuralRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL À RÉGLER',
                            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatXof(amount),
                            style: AppTypography.displayLg.copyWith(
                              color: AppColors.primary,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'MOYEN DE PAIEMENT',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        for (final info in _providers)
                          _ProviderTile(
                            info: info,
                            selected: controller.mobileMoneyProvider.value == info.provider,
                            onTap: () => controller.mobileMoneyProvider.value = info.provider,
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'NUMÉRO DE TÉLÉPHONE',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: '07 00 00 00 00',
                        hintStyle: AppTypography.titleLg.copyWith(
                          color: AppColors.surfaceContainerHighest,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '+225',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.structuralRadius,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.structuralRadius,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.structuralRadius,
                          borderSide: const BorderSide(color: AppColors.primaryFixed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.outline),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Un code de confirmation sera envoyé sur ce numéro.',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller.submitFromPayment();
                          Get.until((route) => route.settings.name == AppRoutes.home);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.structuralRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'PAYER ${formatXof(amount)}',
                              style: AppTypography.titleLg.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                        borderRadius: AppRadii.interactiveRadius,
                        border: Border.all(color: AppColors.outlineVariant15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: AppColors.primaryFixed,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GARANTIE TRANSACTIONNELLE',
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.outline,
                                      fontSize: 11,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Fonds mis sous séquestre par ',
                                      ),
                                      TextSpan(
                                        text: 'AXIOM ENCRYPT',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '. Le marchand ne reçoit le paiement qu\'après '
                                            'validation par vos soins.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final _ProviderInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(
            color: selected ? AppColors.primaryFixed : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      info.initials,
                      style: AppTypography.labelMd.copyWith(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  info.label,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  info.subtitle,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle, color: AppColors.primaryFixed, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
