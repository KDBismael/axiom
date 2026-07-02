import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/shell_controller.dart';

/// Persistent bottom-nav shell hosting the app's three tabs: Dashboard,
/// History, Profile. Tab content is swapped via [IndexedStack] so each tab
/// keeps its state; only the bottom nav itself is shared chrome.
class MainShellView extends GetView<ShellController> {
  const MainShellView({super.key});

  static const _tabs = [HomeView(), HistoryView(), ProfileView()];

  @override
  Widget build(BuildContext context) {
    // Deliberately not using Scaffold.bottomNavigationBar: combined with
    // extendBody it silently dims the entire body (reproduced on-device,
    // both with and without a BackdropFilter involved — a genuine Scaffold
    // bug in this Flutter version, not a styling issue). Composing the nav
    // as a plain Column sibling instead sidesteps it.
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.currentIndex.value,
                children: _tabs,
              ),
            ),
          ),
          const _BottomNav(),
        ],
      ),
    );
  }
}

class _BottomNav extends GetView<ShellController> {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return GlassChrome(
      safeAreaBottom: true,
      child: SizedBox(
        height: 80,
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view,
                label: 'TABLEAU DE BORD',
                active: controller.currentIndex.value == 0,
                onTap: () => controller.changeTab(0),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'HISTORIQUE',
                active: controller.currentIndex.value == 1,
                onTap: () => controller.changeTab(1),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'PROFIL',
                active: controller.currentIndex.value == 2,
                onTap: () => controller.changeTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.emerald : Colors.transparent,
          borderRadius: AppRadii.interactiveRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
