import 'package:get/get.dart';

import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/authentication/views/login_view.dart';
import '../../modules/authentication/views/register_view.dart';
import '../../modules/authentication/views/forgot_password_view.dart';
import '../../modules/dashboard/views/dashboard_view.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardView()),
  ];
}
