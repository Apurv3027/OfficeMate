import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/settlement_repository.dart';
import '../controllers/settlement_controller.dart';

class SettlementBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettlementRepository>()) {
      Get.lazyPut<SettlementRepository>(() => SettlementRepository());
    }

    if (!Get.isRegistered<GroupRepository>()) {
      Get.lazyPut<GroupRepository>(() => GroupRepository());
    }

    Get.lazyPut<SettlementController>(
      () => SettlementController(
        Get.find<SettlementRepository>(),
        Get.find<GroupRepository>(),
      ),
    );
  }
}
