import 'package:get/get.dart';

import '../../../data/models/group_model.dart';
import '../../../data/repositories/group_repository.dart';

class DashboardController extends GetxController {
  final GroupRepository _groupRepository;

  DashboardController(this._groupRepository);

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _groupRepository.getMyGroups();

      groups.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Unable to load your groups.';
    } finally {
      isLoading.value = false;
    }
  }
}
