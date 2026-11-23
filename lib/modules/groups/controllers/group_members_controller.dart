import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/models/group_member_model.dart';
import '../../../data/repositories/group_repository.dart';

class GroupMembersController extends GetxController {
  GroupMembersController(this._groupRepository);

  final GroupRepository _groupRepository;

  final members = <GroupMemberModel>[].obs;
  final isLoading = false.obs;
  final isRemoving = false.obs;

  late String groupId;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get isCurrentUserAdmin {
    return members.any(
      (member) =>
          member.userId == currentUserId && member.isAdmin && member.isActive,
    );
  }

  @override
  void onInit() {
    super.onInit();
    groupId = Get.arguments as String;
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;

      final result = await _groupRepository.getGroupMembers(groupId);

      members.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      isRemoving.value = true;

      await _groupRepository.removeMember(groupId: groupId, memberId: memberId);

      await loadMembers();

      Get.snackbar('Success', 'Member removed successfully.');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isRemoving.value = false;
    }
  }

  Future<void> leaveGroup() async {
    try {
      await _groupRepository.leaveGroup(groupId);

      Get.back();
      Get.snackbar('Success', 'You left the group.');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
