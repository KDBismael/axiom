import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/bindings/initial_binding.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/pending_invite_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Registered manually (not via GetMaterialApp's initialBinding) so the
  // session can be restored before the first frame/route is chosen.
  InitialBinding().dependencies();

  final hasOnboarded = await OnboardingService().hasCompletedOnboarding();
  final authController = Get.find<AuthController>();
  if (hasOnboarded) {
    await authController.restoreSession();
  }

  final String initialRoute;
  if (!hasOnboarded) {
    initialRoute = AppRoutes.onboarding;
  } else if (authController.isAuthenticated) {
    initialRoute = AppRoutes.home;
  } else {
    initialRoute = AppRoutes.login;
  }

  runApp(AxiomApp(initialRoute: initialRoute));
}

class AxiomApp extends StatefulWidget {
  const AxiomApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<AxiomApp> createState() => _AxiomAppState();
}

class _AxiomAppState extends State<AxiomApp> {
  StreamSubscription<String>? _inviteLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeepLinks());
  }

  Future<void> _initDeepLinks() async {
    // Guarded: the app_links platform channel doesn't exist in widget tests
    // (and on platforms without it), which would otherwise crash startup.
    try {
      final deepLinkService = Get.find<DeepLinkService>();
      final initialToken = await deepLinkService.getInitialInviteToken();
      if (initialToken != null) _handleInviteToken(initialToken);
      _inviteLinkSubscription = deepLinkService.inviteTokenStream
          .listen(_handleInviteToken, onError: (_) {});
    } catch (_) {
      // No-op: deep linking simply isn't available in this environment.
    }
  }

  void _handleInviteToken(String token) {
    if (Get.find<AuthController>().isAuthenticated) {
      Get.toNamed(AppRoutes.invitationAlly, arguments: token);
    } else {
      Get.find<PendingInviteService>().stash(token);
    }
  }

  @override
  void dispose() {
    _inviteLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ndeli',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialBinding: InitialBinding(),
      initialRoute: widget.initialRoute,
      getPages: AppPages.pages,
    );
  }
}
