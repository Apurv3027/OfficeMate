import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

class TransactionController extends GetxController {
  final TransactionRepository repository;

  TransactionController(this.repository);

  final transactions = <TransactionModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final selectedType = 'all'.obs;
  final selectedStatus = 'all'.obs;
  final activeDateFilter = 'all'.obs; // 'all', 'today', 'week', 'month', 'custom'

  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  late String groupId;

  List<TransactionModel> get filteredTransactions {
    return transactions.where((transaction) {
      if (selectedType.value == 'purchase' && !transaction.isPurchase) {
        return false;
      }

      if (selectedType.value == 'settlement' && !transaction.isSettlement) {
        return false;
      }

      if (selectedStatus.value != 'all' &&
          transaction.status != selectedStatus.value) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      groupId = args;
      loadTransactions();
    } else {
      errorMessage.value = 'Group ID is missing.';
    }
  }

  Future<void> loadTransactions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await repository.getTransactions(
        groupId: groupId,
        startDate: startDate.value,
        endDate: endDate.value,
      );

      transactions.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Unable to load transactions.';
    } finally {
      isLoading.value = false;
    }
  }

  void changeType(String value) {
    selectedType.value = value;
  }

  void changeStatus(String value) {
    selectedStatus.value = value;
  }

  void applyDatePreset(String preset) {
    activeDateFilter.value = preset;
    final now = DateTime.now();

    switch (preset) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        changeDateRange(start, end);
        break;
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(start.year, start.month, start.day);
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        changeDateRange(startOfDay, endOfDay);
        break;
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        changeDateRange(start, end);
        break;
      case 'all':
      default:
        changeDateRange(null, null);
        break;
    }
  }

  void changeDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    loadTransactions();
  }

  void resetFilters() {
    selectedType.value = 'all';
    selectedStatus.value = 'all';
    activeDateFilter.value = 'all';
    startDate.value = null;
    endDate.value = null;
    loadTransactions();
  }
}
