import 'package:get/get.dart';

import '../../modules/groups/bindings/group_binding.dart';
import '../../modules/groups/views/create_group_view.dart';
import '../../modules/groups/views/group_details_view.dart';
import '../../modules/groups/views/groups_view.dart';
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
    // Splash Screen
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),

    // Authentication Screen
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),

    // Dashboard Screen
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardView()),

    // Groups Screen
    GetPage(
      name: AppRoutes.groups,
      page: () => const GroupsView(),
      binding: GroupBinding(),
    ),

    GetPage(
      name: AppRoutes.createGroup,
      page: () => const CreateGroupView(),
      binding: GroupBinding(),
    ),

    GetPage(
      name: AppRoutes.groupDetails,
      page: () => const GroupDetailsView(),
      binding: GroupBinding(),
    ),
  ];
}
