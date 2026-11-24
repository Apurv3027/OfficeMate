import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/models/group_member_model.dart';
import '../../../data/models/settlement_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/settlement_repository.dart';

class SettlementController extends GetxController {
  final SettlementRepository _repository;
  final GroupRepository _groupRepository;

  SettlementController(this._repository, this._groupRepository);

  final RxList<GroupMemberModel> members = <GroupMemberModel>[].obs;
  final RxList<SettlementModel> settlements = <SettlementModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt selectedReceiverOutstandingPaise = 0.obs;
  final RxBool isLoadingOutstanding = false.obs;

  StreamSubscription<List<SettlementModel>>? _subscription;

  late String groupId;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  String get currentUserIdForUi => currentUserId;

  List<SettlementModel> get pendingSettlements =>
      settlements.where((s) => s.isPending).toList();

  List<SettlementModel> get confirmedSettlements =>
      settlements.where((s) => s.isConfirmed).toList();

  List<SettlementModel> get otherSettlements =>
      settlements.where((s) => s.isRejected || s.isCancelled).toList();

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;
    if (arguments is String && arguments.isNotEmpty) {
      groupId = arguments;
      loadMembers();
      watchSettlements();
    } else {
      isLoading.value = false;
      errorMessage.value = 'Group ID is missing.';
    }
  }

  Future<void> loadMembers() async {
    try {
      final result = await _groupRepository.getGroupMembers(groupId);
      members.assignAll(result.where((member) => member.isActive).toList());
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  void watchSettlements() {
    _subscription?.cancel();
    isLoading.value = true;
    errorMessage.value = '';

    _subscription = _repository.watchSettlements(groupId).listen(
      (result) {
        settlements.assignAll(result);
        isLoading.value = false;
      },
      onError: (error) {
        errorMessage.value = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
        isLoading.value = false;
      },
    );
  }

  Future<void> fetchOutstandingForReceiver(String receiverId) async {
    try {
      isLoadingOutstanding.value = true;
      final amount = await _repository.getOutstandingAmount(
        groupId: groupId,
        fromUserId: currentUserId,
        toUserId: receiverId,
      );
      selectedReceiverOutstandingPaise.value = amount;
    } catch (_) {
      selectedReceiverOutstandingPaise.value = 0;
    } finally {
      isLoadingOutstanding.value = false;
    }
  }

  Future<void> createSettlement({
    required String toUserId,
    required int amountPaise,
    required String note,
  }) async {
    try {
      isSaving.value = true;

      await _repository.createSettlement(
        groupId: groupId,
        toUserId: toUserId,
        amountPaise: amountPaise,
        note: note,
      );

      Get.back(result: true);

      Get.snackbar(
        'Success',
        'Payment recorded. Waiting for receiver confirmation.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmPayment(String settlementId) async {
    await _performAction(
      () => _repository.confirmSettlement(
        groupId: groupId,
        settlementId: settlementId,
      ),
      'Payment confirmed successfully.',
    );
  }

  Future<void> rejectPayment(String settlementId) async {
    await _performAction(
      () => _repository.rejectSettlement(
        groupId: groupId,
        settlementId: settlementId,
      ),
      'Payment rejected.',
    );
  }

  Future<void> cancelPayment(String settlementId) async {
    await _performAction(
      () => _repository.cancelSettlement(
        groupId: groupId,
        settlementId: settlementId,
      ),
      'Pending payment cancelled.',
    );
  }

  Future<void> _performAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      Get.snackbar(
        'Success',
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
