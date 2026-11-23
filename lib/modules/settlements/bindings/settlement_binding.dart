import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/settlement_repository.dart';
import '../controllers/settlement_controller.dart';

class SettlementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettlementRepository>(() => SettlementRepository());

    Get.lazyPut<SettlementController>(
      () => SettlementController(
        Get.find<SettlementRepository>(),
        GroupRepository(),
      ),
    );
  }
}
