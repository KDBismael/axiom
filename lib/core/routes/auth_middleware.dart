import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'app_routes.dart';

/// Guards protected routes — redirects to /login when there's no
/// authenticated session.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
