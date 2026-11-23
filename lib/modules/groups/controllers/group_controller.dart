import 'dart:developer';

import 'package:get/get.dart';

import '../../../data/models/group_model.dart';
import '../../../data/models/group_member_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../modules/authentication/controllers/auth_controller.dart';

class GroupController extends GetxController {
  final GroupRepository _repository;
  final AuthController _authController;

  GroupController(this._repository, this._authController);

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxList<GroupMemberModel> members = <GroupMemberModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isJoining = false.obs;

  final RxString selectedGroupId = ''.obs;

  String get currentUserId => _authController.currentUser.value?.uid ?? '';

  String get currentUserName =>
      _authController.currentUser.value?.fullName ?? '';

  String get currentUserEmail => _authController.currentUser.value?.email ?? '';

  bool get isCurrentUserAdmin {
    return members.any(
      (member) =>
          member.userId == currentUserId && member.isAdmin && member.isActive,
    );
  }

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      isLoading.value = true;
      final result = await _repository.getMyGroups();
      groups.assignAll(result);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      if (name.trim().length < 3) {
        throw Exception('Group name must contain at least 3 characters.');
      }

      isCreating.value = true;

      await _repository.createGroup(
        name: name,
        description: description,
        fullName: currentUserName,
        email: currentUserEmail,
      );

      await loadGroups();

      Get.back();

      Get.snackbar(
        'Success',
        'Group created successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError(e);
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> joinGroup(String inviteCode) async {
    try {
      isJoining.value = true;

      await _repository.joinGroup(inviteCode);

      await loadGroups();

      Get.back();

      Get.snackbar(
        'Success',
        'You joined the group successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError(e);
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> loadMembers(String groupId) async {
    try {
      selectedGroupId.value = groupId;
      isLoading.value = true;

      final result = await _repository.getGroupMembers(groupId);
      members.assignAll(result);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _repository.removeMember(groupId: groupId, memberId: memberId);

      await loadMembers(groupId);

      Get.snackbar(
        'Success',
        'Member removed successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(groupId);

      members.clear();
      await loadGroups();

      Get.back();

      Get.snackbar(
        'Success',
        'You left the group.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    log("Error: $error");

    Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
  }
}
