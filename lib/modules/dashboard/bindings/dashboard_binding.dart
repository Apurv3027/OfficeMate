import 'package:get/get.dart';

import '../../../data/repositories/balance_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/repositories/settlement_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GroupRepository>()) {
      Get.lazyPut<GroupRepository>(() => GroupRepository());
    }

    if (!Get.isRegistered<PurchaseRepository>()) {
      Get.lazyPut<PurchaseRepository>(() => PurchaseRepository());
    }

    if (!Get.isRegistered<SettlementRepository>()) {
      Get.lazyPut<SettlementRepository>(() => SettlementRepository());
    }

    if (!Get.isRegistered<BalanceRepository>()) {
      Get.lazyPut<BalanceRepository>(
        () => BalanceRepository(
          groupRepository: Get.find<GroupRepository>(),
          purchaseRepository: Get.find<PurchaseRepository>(),
          settlementRepository: Get.find<SettlementRepository>(),
        ),
      );
    }

    if (!Get.isRegistered<TransactionRepository>()) {
      Get.lazyPut<TransactionRepository>(() => TransactionRepository());
    }

    Get.lazyPut<DashboardController>(
      () => DashboardController(
        groupRepository: Get.find<GroupRepository>(),
        balanceRepository: Get.find<BalanceRepository>(),
        purchaseRepository: Get.find<PurchaseRepository>(),
        settlementRepository: Get.find<SettlementRepository>(),
        transactionRepository: Get.find<TransactionRepository>(),
      ),
    );
  }
}
