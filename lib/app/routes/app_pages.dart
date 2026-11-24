import 'package:get/get.dart';

import '../../modules/balances/bindings/balance_binding.dart';
import '../../modules/balances/views/balance_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/groups/bindings/group_binding.dart';
import '../../modules/groups/bindings/group_members_binding.dart';
import '../../modules/groups/views/create_group_view.dart';
import '../../modules/groups/views/group_details_view.dart';
import '../../modules/groups/views/group_members_view.dart';
import '../../modules/groups/views/groups_view.dart';
import '../../modules/purchases/bindings/purchase_binding.dart';
import '../../modules/purchases/views/add_purchase_view.dart';
import '../../modules/purchases/views/purchase_details_view.dart';
import '../../modules/purchases/views/purchases_view.dart';
import '../../modules/reports/bindings/report_binding.dart';
import '../../modules/reports/views/reports_view.dart';
import '../../modules/settlements/bindings/settlement_binding.dart';
import '../../modules/settlements/views/add_settlement_view.dart';
import '../../modules/settlements/views/settlements_view.dart';
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
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),

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

    // Purchases Screen
    GetPage(
      name: AppRoutes.purchases,
      page: () => const PurchasesView(),
      binding: PurchaseBinding(),
    ),

    GetPage(
      name: AppRoutes.addPurchase,
      page: () => const AddPurchaseView(),
      binding: PurchaseBinding(),
    ),

    GetPage(
      name: AppRoutes.purchaseDetails,
      page: () => const PurchaseDetailsView(),
      binding: PurchaseBinding(),
    ),

    // Balances Screen
    GetPage(
      name: AppRoutes.balances,
      page: () => const BalanceView(),
      binding: BalanceBinding(),
    ),

    // Settlements Screen
    GetPage(
      name: AppRoutes.settlements,
      page: () => const SettlementsView(),
      binding: SettlementBinding(),
    ),

    GetPage(
      name: AppRoutes.addSettlement,
      page: () => const AddSettlementView(),
      binding: SettlementBinding(),
    ),

    // Reports Screen
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
      binding: ReportBinding(),
    ),

    // Group Members Screen
    GetPage(
      name: AppRoutes.groupMembers,
      page: () => const GroupMembersView(),
      binding: GroupMembersBinding(),
    ),
  ];
}
