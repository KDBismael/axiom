import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Home delegates directly to the quest list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed(AppRoutes.quests);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(strokeWidth: 1)),
    );
  }
}
