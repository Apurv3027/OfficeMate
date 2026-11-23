import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_formatters.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/report_controller.dart';

class ReportsView extends GetView<ReportController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reports'),
        actions: [
          IconButton(
            onPressed: controller.loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.loadReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = controller.report.value;

        return RefreshIndicator(
          onRefresh: controller.loadReport,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDateFilters(context),

              const SizedBox(height: 20),

              _buildSummaryCards(data),

              const SizedBox(height: 24),

              _sectionTitle('Highest Spender'),

              const SizedBox(height: 10),

              _buildHighestSpender(data),

              const SizedBox(height: 24),

              _sectionTitle('Member-wise Expenses'),

              const SizedBox(height: 10),

              _buildMemberExpenses(data),

              const SizedBox(height: 24),

              _sectionTitle('Daily Expenses'),

              const SizedBox(height: 10),

              _buildDailyExpenses(data),

              const SizedBox(height: 24),

              _sectionTitle('Settlement Summary'),

              const SizedBox(height: 10),

              _buildSettlementSummary(data),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Period',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterButton('Today'),
            _filterButton('This Week'),
            _filterButton('This Month'),
            _filterButton('Last 30 Days'),
            OutlinedButton.icon(
              onPressed: () async {
                final current = controller.selectedRange.value;

                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: current,
                );

                if (range != null) {
                  await controller.selectCustomRange(range);
                }
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Custom'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Obx(() {
          final range = controller.selectedRange.value;

          return Text(
            '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }),
      ],
    );
  }

  Widget _filterButton(String label) {
    return OutlinedButton(
      onPressed: () => controller.selectPreset(label),
      child: Text(label),
    );
  }

  Widget _buildSummaryCards(ReportSummaryModel data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Expenses',
                value: AppFormatters.currencyFromPaise(data.totalExpensePaise),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Purchases',
                value: '${data.totalPurchases}',
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _summaryCard(
          title: 'Confirmed Settlements',
          value: AppFormatters.currencyFromPaise(
            data.totalConfirmedSettlementPaise,
          ),
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildHighestSpender(ReportSummaryModel data) {
    if (data.highestSpenderId.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expense records for this period.'),
        ),
      );
    }

    final name = data.memberNames[data.highestSpenderId] ?? 'Unknown';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
        title: Text(name),
        subtitle: const Text('Highest amount paid'),
        trailing: Text(
          AppFormatters.currencyFromPaise(data.highestSpenderAmountPaise),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMemberExpenses(ReportSummaryModel data) {
    final ids = <String>{
      ...data.paidByMember.keys,
      ...data.sharesByMember.keys,
    }.toList();

    if (ids.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No member expenses available.'),
        ),
      );
    }

    return Column(
      children: ids.map((id) {
        final name = data.memberNames[id] ?? 'Unknown Member';
        final paid = data.paidByMember[id] ?? 0;
        final share = data.sharesByMember[id] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _amountRow('Total Paid', paid),
                const SizedBox(height: 6),
                _amountRow('Total Share', share),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _amountRow(String label, int amountPaise) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          AppFormatters.currencyFromPaise(amountPaise),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDailyExpenses(ReportSummaryModel data) {
    if (data.dailyExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No daily expenses available.'),
        ),
      );
    }

    final entries = data.dailyExpenses.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            a.key.compareTo(b.key),
      );

    final maxAmount = entries
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.map((entry) {
            final progress = maxAmount == 0 ? 0.0 : entry.value / maxAmount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        AppFormatters.currencyFromPaise(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSettlementSummary(ReportSummaryModel data) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: const Text('Confirmed payments'),
        subtitle: const Text(
          'Payments confirmed by the receiver during the selected period',
        ),
        trailing: Text(
          AppFormatters.currencyFromPaise(data.totalConfirmedSettlementPaise),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
