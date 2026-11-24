import 'package:get/get.dart';

import '../../../core/utils/expense_split_helper.dart';
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
    if (selectedParticipants.isEmpty || amountPaise <= 0) return {};
    return ExpenseSplitHelper.calculateEqualSplit(
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
    return ExpenseSplitHelper.validateCustomSplit(
      amountPaise: amountPaise,
      splitAmounts: customSplits,
      participantIds: selectedParticipants.toList(),
    );
  }

  Future<void> addPurchase({
    required String title,
    required String description,
    required int amountPaise,
    required DateTime purchasedAt,
    required String categoryId,
    required String categoryName,
    Map<String, int>? splitAmounts,
    String? splitType,
  }) async {
    try {
      if (selectedParticipants.isEmpty) {
        throw Exception('Select at least one participant.');
      }

      if (paidBy.value.isEmpty) {
        throw Exception('Select who paid for this purchase.');
      }

      isSaving.value = true;

      final effectiveSplitType = splitType ?? this.splitType.value;
      final splits = splitAmounts ??
          (effectiveSplitType == 'equal'
              ? getEqualSplits(amountPaise)
              : Map<String, int>.from(customSplits));

      if (effectiveSplitType == 'custom' &&
          !ExpenseSplitHelper.validateCustomSplit(
            amountPaise: amountPaise,
            splitAmounts: splits,
            participantIds: selectedParticipants.toList(),
          )) {
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
        splitType: effectiveSplitType,
        purchasedAt: purchasedAt,
        categoryId: categoryId,
        categoryName: categoryName,
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
