import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/report_summary_model.dart';
import '../../../data/repositories/report_repository.dart';

class ReportController extends GetxController {
  final ReportRepository _repository;

  ReportController(this._repository);

  late final String groupId;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ReportSummaryModel> report = ReportSummaryModel.empty().obs;

  final Rx<DateTimeRange> selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  ).obs;

  @override
  void onInit() {
    super.onInit();

    groupId = Get.arguments as String;
    loadReport();
  }

  Future<void> loadReport() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _repository.getGroupReport(
        groupId: groupId,
        startDate: selectedRange.value.start,
        endDate: selectedRange.value.end,
      );

      report.value = result;
    } catch (e) {
      errorMessage.value = 'Unable to load report. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectPreset(String preset) async {
    final now = DateTime.now();

    DateTime start;
    DateTime end = now;

    switch (preset) {
      case 'Today':
        start = now;
        break;

      case 'This Week':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        break;

      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;

      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 29));
        break;

      default:
        start = now.subtract(const Duration(days: 6));
    }

    selectedRange.value = DateTimeRange(start: start, end: end);

    await loadReport();
  }

  Future<void> selectCustomRange(DateTimeRange range) async {
    selectedRange.value = range;
    await loadReport();
  }
}
