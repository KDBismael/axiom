import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/bindings/initial_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/onboarding_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final hasOnboarded = await OnboardingService().hasCompletedOnboarding();
  runApp(
    AxiomApp(
      initialRoute: hasOnboarded ? AppRoutes.home : AppRoutes.onboarding,
    ),
  );
}

class AxiomApp extends StatelessWidget {
  const AxiomApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Axiom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    );
  }
}
