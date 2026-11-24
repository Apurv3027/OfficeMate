import 'package:get/get.dart';

import '../../../data/repositories/balance_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/repositories/settlement_repository.dart';
import '../controllers/balance_controller.dart';

class BalanceBinding extends Bindings {
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

    Get.lazyPut<BalanceRepository>(
      () => BalanceRepository(
        groupRepository: Get.find<GroupRepository>(),
        purchaseRepository: Get.find<PurchaseRepository>(),
        settlementRepository: Get.find<SettlementRepository>(),
      ),
    );

    Get.lazyPut<BalanceController>(
      () => BalanceController(
        repository: Get.find<BalanceRepository>(),
      ),
    );
  }
}
