import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class TransactionsView extends GetView<TransactionController> {
  const TransactionsView({super.key});

  String _formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: controller.startDate.value != null &&
              controller.endDate.value != null
          ? DateTimeRange(
              start: controller.startDate.value!,
              end: controller.endDate.value!,
            )
          : null,
    );

    if (picked != null) {
      controller.activeDateFilter.value = 'custom';
      final start = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      final end = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      controller.changeDateRange(start, end);
    }
  }

  void _showSettlementDetails(
    BuildContext context,
    TransactionModel transaction,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(transaction.status.toUpperCase()),
                    backgroundColor:
                        _statusColor(transaction.status).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _statusColor(transaction.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                _formatAmount(transaction.amountPaise),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Payment', transaction.description),
              _detailRow('Initiated By', transaction.primaryUserName),
              _detailRow(
                'Date',
                DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed(
                      AppRoutes.settlements,
                      arguments: controller.groupId,
                    );
                  },
                  child: const Text('View In Settlements'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final isPurchase = transaction.isPurchase;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPurchase
              ? Colors.blue.withValues(alpha: 0.12)
              : Colors.green.withValues(alpha: 0.12),
          child: Icon(
            isPurchase ? Icons.shopping_bag_outlined : Icons.swap_horiz,
            color: isPurchase ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isPurchase
                  ? 'Paid by ${transaction.primaryUserName} · ${DateFormat('dd MMM').format(transaction.date)}'
                  : '${transaction.description} · ${DateFormat('dd MMM').format(transaction.date)}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(transaction.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPurchase ? 'PURCHASE' : transaction.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(transaction.status),
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          _formatAmount(transaction.amountPaise),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          if (isPurchase) {
            Get.toNamed(
              AppRoutes.purchaseDetails,
              arguments: {
                'groupId': controller.groupId,
                'purchaseId': transaction.id,
              },
            );
          } else {
            _showSettlementDetails(context, transaction);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('All'),
                          icon: Icon(Icons.list_alt),
                        ),
                        ButtonSegment(
                          value: 'purchase',
                          label: Text('Purchases'),
                          icon: Icon(Icons.shopping_bag_outlined),
                        ),
                        ButtonSegment(
                          value: 'settlement',
                          label: Text('Settlements'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                      ],
                      selected: {controller.selectedType.value},
                      onSelectionChanged: (values) {
                        controller.changeType(values.first);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Date filter chips
                Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Time'),
                          selected: controller.activeDateFilter.value == 'all',
                          onSelected: (_) => controller.applyDatePreset('all'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Today'),
                          selected: controller.activeDateFilter.value == 'today',
                          onSelected: (_) => controller.applyDatePreset('today'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('This Week'),
                          selected: controller.activeDateFilter.value == 'week',
                          onSelected: (_) => controller.applyDatePreset('week'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('This Month'),
                          selected: controller.activeDateFilter.value == 'month',
                          onSelected: (_) => controller.applyDatePreset('month'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                            controller.activeDateFilter.value == 'custom' &&
                                    controller.startDate.value != null
                                ? '${DateFormat('dd MMM').format(controller.startDate.value!)} - ${DateFormat('dd MMM').format(controller.endDate.value!)}'
                                : 'Custom Date...',
                          ),
                          selected:
                              controller.activeDateFilter.value == 'custom',
                          onSelected: (_) => _pickCustomDateRange(context),
                        ),
                        if (controller.activeDateFilter.value != 'all' ||
                            controller.selectedType.value != 'all' ||
                            controller.selectedStatus.value != 'all') ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: controller.resetFilters,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Reset'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Status filter (when settlements or all)
                Obx(() {
                  if (controller.selectedType.value == 'purchase') {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          ...['all', 'pending', 'confirmed', 'rejected', 'cancelled']
                              .map((status) {
                            final isSelected =
                                controller.selectedStatus.value == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) =>
                                    controller.changeStatus(status),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // Transaction list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.errorMessage.value),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: controller.loadTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final list = controller.filteredTransactions;

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 54,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your filters or date range.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: controller.resetFilters,
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadTransactions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionTile(context, list[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
