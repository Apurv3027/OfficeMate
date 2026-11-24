import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/member_balance_model.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/models/settlement_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/balance_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/repositories/settlement_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../authentication/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final GroupRepository _groupRepository;
  final BalanceRepository _balanceRepository;
  final PurchaseRepository _purchaseRepository;
  final SettlementRepository _settlementRepository;
  final TransactionRepository _transactionRepository;

  DashboardController({
    required GroupRepository groupRepository,
    required BalanceRepository balanceRepository,
    required PurchaseRepository purchaseRepository,
    required SettlementRepository settlementRepository,
    required TransactionRepository transactionRepository,
  })  : _groupRepository = groupRepository,
        _balanceRepository = balanceRepository,
        _purchaseRepository = purchaseRepository,
        _settlementRepository = settlementRepository,
        _transactionRepository = transactionRepository;

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxString selectedGroupId = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingGroupData = false.obs;
  final RxString errorMessage = ''.obs;

  // Group-specific dashboard values
  final RxInt totalGroupExpensesPaise = 0.obs;
  final RxInt myTotalPaidPaise = 0.obs;
  final RxInt myTotalSharePaise = 0.obs;
  final RxInt myNetBalancePaise = 0.obs;
  final RxInt pendingSettlementsCount = 0.obs;
  final RxInt pendingSettlementsTotalPaise = 0.obs;

  final RxList<TransactionModel> recentTransactions = <TransactionModel>[].obs;

  StreamSubscription<List<MemberBalanceModel>>? _balanceSubscription;
  StreamSubscription<List<PurchaseModel>>? _purchaseSubscription;
  StreamSubscription<List<SettlementModel>>? _settlementSubscription;

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get userName {
    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      final name = authCtrl.currentUser.value?.fullName;
      if (name != null && name.isNotEmpty) return name;
    }
    return FirebaseService.auth.currentUser?.displayName ?? 'Friend';
  }

  GroupModel? get selectedGroup {
    if (selectedGroupId.value.isEmpty) return null;
    return groups.firstWhereOrNull((g) => g.id == selectedGroupId.value);
  }

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

      if (groups.isNotEmpty) {
        if (selectedGroupId.value.isEmpty ||
            !groups.any((g) => g.id == selectedGroupId.value)) {
          selectedGroupId.value = groups.first.id;
        }
        await loadSelectedGroupData();
      } else {
        selectedGroupId.value = '';
        _resetGroupMetrics();
      }
    } catch (e) {
      errorMessage.value = 'Unable to load your groups.';
    } finally {
      isLoading.value = false;
    }
  }

  void selectGroup(String groupId) {
    if (selectedGroupId.value != groupId) {
      selectedGroupId.value = groupId;
      loadSelectedGroupData();
    }
  }

  Future<void> loadSelectedGroupData() async {
    final groupId = selectedGroupId.value;
    if (groupId.isEmpty) return;

    _cancelSubscriptions();
    isLoadingGroupData.value = true;

    try {
      // 1. Watch balances using BalanceRepository
      _balanceSubscription = _balanceRepository.watchBalances(groupId).listen(
        (balanceList) {
          final myBalance = balanceList.firstWhereOrNull(
            (b) => b.userId == currentUserId,
          );
          if (myBalance != null) {
            myTotalPaidPaise.value = myBalance.totalPaidPaise;
            myTotalSharePaise.value = myBalance.totalSharePaise;
            myNetBalancePaise.value = myBalance.netBalancePaise;
          } else {
            myTotalPaidPaise.value = 0;
            myTotalSharePaise.value = 0;
            myNetBalancePaise.value = 0;
          }
        },
        onError: (_) {},
      );

      // 2. Watch purchases for total group expenses
      _purchaseSubscription = _purchaseRepository.watchPurchases(groupId).listen(
        (purchaseList) {
          totalGroupExpensesPaise.value = purchaseList.fold<int>(
            0,
            (sum, p) => sum + p.amountPaise,
          );
        },
        onError: (_) {},
      );

      // 3. Watch settlements for pending payments
      _settlementSubscription = _settlementRepository.watchSettlements(groupId).listen(
        (settlementList) {
          final pending = settlementList.where((s) => s.isPending).toList();
          pendingSettlementsCount.value = pending.length;
          pendingSettlementsTotalPaise.value = pending.fold<int>(
            0,
            (sum, s) => sum + s.amountPaise,
          );
        },
        onError: (_) {},
      );

      // 4. Load recent transactions (top 5)
      final allTransactions = await _transactionRepository.getTransactions(
        groupId: groupId,
      );
      recentTransactions.assignAll(allTransactions.take(5));
    } catch (_) {
      // Keep UI functional even if a sub-query fails
    } finally {
      isLoadingGroupData.value = false;
    }
  }

  void _resetGroupMetrics() {
    _cancelSubscriptions();
    totalGroupExpensesPaise.value = 0;
    myTotalPaidPaise.value = 0;
    myTotalSharePaise.value = 0;
    myNetBalancePaise.value = 0;
    pendingSettlementsCount.value = 0;
    pendingSettlementsTotalPaise.value = 0;
    recentTransactions.clear();
  }

  void _cancelSubscriptions() {
    _balanceSubscription?.cancel();
    _purchaseSubscription?.cancel();
    _settlementSubscription?.cancel();
    _balanceSubscription = null;
    _purchaseSubscription = null;
    _settlementSubscription = null;
  }

  @override
  void onClose() {
    _cancelSubscriptions();
    super.onClose();
  }
}
