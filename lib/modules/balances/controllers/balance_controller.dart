import 'dart:async';
import 'package:get/get.dart';

import '../../../data/models/member_balance_model.dart';
import '../../../data/repositories/balance_repository.dart';

class BalanceController extends GetxController {
  final BalanceRepository _repository;

  BalanceController(this._repository);

  final RxList<MemberBalanceModel> balances = <MemberBalanceModel>[].obs;
  StreamSubscription<List<MemberBalanceModel>>? _balanceSubscription;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  late String groupId;

  @override
  void onInit() {
    super.onInit();

    groupId = Get.arguments as String;

    loadBalances();
  }

  void loadBalances() {
    _balanceSubscription?.cancel();

    isLoading.value = true;
    errorMessage.value = '';

    _balanceSubscription = _repository
        .watchBalances(groupId)
        .listen(
          (result) {
            balances.assignAll(result);
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

  int get totalGroupPaidPaise {
    return balances.fold<int>(0, (sum, item) => sum + item.totalPaidPaise);
  }

  int get totalGroupSharePaise {
    return balances.fold<int>(0, (sum, item) => sum + item.totalSharePaise);
  }

  int get totalReceivablePaise {
    return balances
        .where((item) => item.netBalancePaise > 0)
        .fold<int>(0, (sum, item) => sum + item.netBalancePaise);
  }

  int get totalPayablePaise {
    return balances
        .where((item) => item.netBalancePaise < 0)
        .fold<int>(0, (sum, item) => sum + item.netBalancePaise.abs());
  }

  MemberBalanceModel? getMemberBalance(String userId) {
    final index = balances.indexWhere((item) => item.userId == userId);

    if (index == -1) return null;

    return balances[index];
  }

  @override
  void onClose() {
    _balanceSubscription?.cancel();
    super.onClose();
  }
}
