import 'package:get/get.dart';

import '../../../data/repositories/balance_repository.dart';
import '../controllers/balance_controller.dart';

class BalanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BalanceRepository>(() => BalanceRepository());

    Get.lazyPut<BalanceController>(
      () => BalanceController(Get.find<BalanceRepository>()),
    );
  }
}
