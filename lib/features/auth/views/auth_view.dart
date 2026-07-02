import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('AXIOM', style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 4)),
              const SizedBox(height: 8),
              Text('Accountability. No excuses.', style: theme.textTheme.bodyMedium),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.quests),
                child: const Text('GET STARTED'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.quests),
                child: const Text('SIGN IN'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
