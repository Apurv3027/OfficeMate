import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/member_balance_model.dart';
import '../../../data/repositories/balance_repository.dart';

class BalanceController extends GetxController {
  final BalanceRepository repository;

  BalanceController({
    required this.repository,
  });

  final balances = <MemberBalanceModel>[].obs;

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  StreamSubscription<List<MemberBalanceModel>>? _subscription;

  String groupId = '';

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;

    if (arguments is String && arguments.isNotEmpty) {
      groupId = arguments;
      watchBalances();
    } else {
      isLoading.value = false;
      errorMessage.value = 'Group ID is missing.';
    }
  }

  void watchBalances() {
    isLoading.value = true;
    errorMessage.value = '';

    _subscription?.cancel();

    _subscription = repository.watchBalances(groupId).listen(
      (data) {
        balances.assignAll(data);
        isLoading.value = false;
        errorMessage.value = '';
      },
      onError: (error) {
        isLoading.value = false;
        errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      },
    );
  }

  MemberBalanceModel? get currentUserBalance {
    final currentUserId = repository.currentUserId;

    for (final balance in balances) {
      if (balance.userId == currentUserId) {
        return balance;
      }
    }

    return null;
  }

  int get totalGroupExpensePaise {
    return balances.fold(
      0,
      (sum, balance) => sum + balance.totalSharePaise,
    );
  }

  int get totalGroupPaidPaise {
    return balances.fold(
      0,
      (sum, balance) => sum + balance.totalPaidPaise,
    );
  }

  int get totalToReceivePaise {
    return balances
        .where((balance) => balance.shouldReceive)
        .fold(0, (sum, balance) => sum + balance.netBalancePaise);
  }

  int get totalToPayPaise {
    return balances
        .where((balance) => balance.shouldPay)
        .fold(0, (sum, balance) => sum + balance.absoluteBalancePaise);
  }

  // Backward-compatible helpers
  int get totalGroupSharePaise => totalGroupExpensePaise;
  int get totalReceivablePaise => totalToReceivePaise;
  int get totalPayablePaise => totalToPayPaise;
  void loadBalances() => watchBalances();
  MemberBalanceModel? getMemberBalance(String userId) {
    final index = balances.indexWhere((item) => item.userId == userId);
    return index == -1 ? null : balances[index];
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
