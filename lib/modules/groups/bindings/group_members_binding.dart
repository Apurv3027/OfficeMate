import 'package:get/get.dart';

import '../../../data/repositories/group_repository.dart';
import '../controllers/group_members_controller.dart';

class GroupMembersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupMembersController>(
      () => GroupMembersController(Get.find<GroupRepository>()),
    );
  }
}
