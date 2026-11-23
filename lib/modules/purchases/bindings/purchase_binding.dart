import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../controllers/purchase_controller.dart';

class PurchaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseRepository>(() => PurchaseRepository());

    Get.lazyPut<PurchaseController>(
      () =>
          PurchaseController(Get.find<PurchaseRepository>(), GroupRepository()),
    );
  }
}
