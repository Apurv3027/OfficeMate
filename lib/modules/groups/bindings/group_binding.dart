import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../../authentication/controllers/auth_controller.dart';
import '../controllers/group_controller.dart';

class GroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupRepository>(() => GroupRepository());

    Get.lazyPut<GroupController>(
      () => GroupController(
        Get.find<GroupRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
