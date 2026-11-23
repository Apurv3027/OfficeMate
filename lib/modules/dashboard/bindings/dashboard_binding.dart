import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GroupRepository>()) {
      Get.lazyPut<GroupRepository>(() => GroupRepository());
    }

    Get.lazyPut<DashboardController>(
      () => DashboardController(Get.find<GroupRepository>()),
    );
  }
}
