import 'package:get/get.dart';

import '../../../data/models/group_member_model.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository _repository;
  final GroupRepository _groupRepository;

  PurchaseController(this._repository, this._groupRepository);

  final RxList<GroupMemberModel> members = <GroupMemberModel>[].obs;

  final RxList<PurchaseModel> purchases = <PurchaseModel>[].obs;

  final RxList<String> selectedParticipants = <String>[].obs;

  final RxMap<String, int> customSplits = <String, int>{}.obs;

  final RxString paidBy = ''.obs;
  final RxString splitType = 'equal'.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  String groupId = '';

  void initialize(String id) {
    groupId = id;
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;

      final result = await _groupRepository.getGroupMembers(groupId);

      members.assignAll(result.where((member) => member.isActive).toList());

      if (paidBy.value.isEmpty && members.isNotEmpty) {
        paidBy.value = members.first.userId;
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleParticipant(String userId) {
    if (selectedParticipants.contains(userId)) {
      selectedParticipants.remove(userId);
    } else {
      selectedParticipants.add(userId);
    }

    if (splitType.value == 'custom') {
      customSplits.remove(userId);
    }
  }

  void selectAllParticipants() {
    selectedParticipants.assignAll(members.map((member) => member.userId));
  }

  void clearParticipants() {
    selectedParticipants.clear();
    customSplits.clear();
  }

  void changeSplitType(String value) {
    splitType.value = value;
    customSplits.clear();
  }

  Map<String, int> getEqualSplits(int amountPaise) {
    return _repository.calculateEqualSplit(
      amountPaise: amountPaise,
      participantIds: selectedParticipants.toList(),
    );
  }

  void updateCustomSplit(String userId, int amountPaise) {
    customSplits[userId] = amountPaise;
  }

  int get customSplitTotal {
    return customSplits.values.fold<int>(0, (sum, amount) => sum + amount);
  }

  bool isCustomSplitValid(int amountPaise) {
    if (selectedParticipants.isEmpty) return false;

    if (selectedParticipants.any((id) => !customSplits.containsKey(id))) {
      return false;
    }

    return customSplitTotal == amountPaise &&
        customSplits.values.every((amount) => amount >= 0);
  }

  Future<void> addPurchase({
    required String title,
    required String description,
    required int amountPaise,
    required DateTime purchasedAt,
  }) async {
    try {
      if (selectedParticipants.isEmpty) {
        throw Exception('Select at least one participant.');
      }

      if (paidBy.value.isEmpty) {
        throw Exception('Select who paid for this purchase.');
      }

      isSaving.value = true;

      final splits = splitType.value == 'equal'
          ? getEqualSplits(amountPaise)
          : Map<String, int>.from(customSplits);

      if (splitType.value == 'custom' && !isCustomSplitValid(amountPaise)) {
        throw Exception('Custom shares must add up to the purchase amount.');
      }

      final payer = members.firstWhere(
        (member) => member.userId == paidBy.value,
      );

      await _repository.addPurchase(
        groupId: groupId,
        title: title,
        description: description,
        amountPaise: amountPaise,
        paidBy: payer.userId,
        paidByName: payer.fullName,
        participantIds: selectedParticipants.toList(),
        splitAmounts: splits,
        splitType: splitType.value,
        purchasedAt: purchasedAt,
      );

      Get.back(result: true);

      Get.snackbar(
        'Success',
        'Purchase added successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void _showError(Object error) {
    Get.snackbar(
      'Error',
      error.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
