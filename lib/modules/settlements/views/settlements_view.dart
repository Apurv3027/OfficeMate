import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/settlement_helper.dart';
import '../../../data/models/settlement_model.dart';
import '../controllers/settlement_controller.dart';

class SettlementsView extends GetView<SettlementController> {
  const SettlementsView({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
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

  void _showSettlementDetails(
    BuildContext context,
    SettlementModel settlement,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentUid = controller.currentUserId;
        final isReceiver = settlement.toUserId == currentUid;
        final isSender = settlement.fromUserId == currentUid;

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
                    label: Text(settlement.status.toUpperCase()),
                    backgroundColor: _statusColor(settlement.status).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _statusColor(settlement.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                SettlementHelper.formatRupees(settlement.amountPaise),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('From', settlement.fromUserName),
              _detailRow('To', settlement.toUserName),
              if (settlement.note.isNotEmpty)
                _detailRow('Note', settlement.note),
              if (settlement.createdAt != null)
                _detailRow(
                  'Created At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(settlement.createdAt!),
                ),
              if (settlement.confirmedAt != null)
                _detailRow(
                  'Confirmed At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(settlement.confirmedAt!),
                ),
              if (settlement.rejectedAt != null)
                _detailRow(
                  'Rejected At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(settlement.rejectedAt!),
                ),
              if (settlement.cancelledAt != null)
                _detailRow(
                  'Cancelled At',
                  DateFormat('dd MMM yyyy, hh:mm a').format(settlement.cancelledAt!),
                ),
              const SizedBox(height: 20),
              if (settlement.isPending && isReceiver) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          controller.rejectPayment(settlement.id);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject Payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          controller.confirmPayment(settlement.id);
                        },
                        child: const Text('Confirm Received'),
                      ),
                    ),
                  ],
                ),
              ],
              if (settlement.isPending && isSender) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.cancelPayment(settlement.id);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel Payment'),
                  ),
                ),
              ],
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

  Widget _buildSettlementCard(BuildContext context, SettlementModel settlement) {
    final currentUid = controller.currentUserId;
    final isReceiver = settlement.toUserId == currentUid;
    final isSender = settlement.fromUserId == currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSettlementDetails(context, settlement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _statusColor(settlement.status).withValues(alpha: 0.15),
                    child: Icon(
                      Icons.swap_horiz,
                      color: _statusColor(settlement.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${settlement.fromUserName} → ${settlement.toUserName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (settlement.createdAt != null)
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(settlement.createdAt!),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    SettlementHelper.formatRupees(settlement.amountPaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              if (settlement.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  settlement.note,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      settlement.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(settlement.status),
                      ),
                    ),
                    backgroundColor: _statusColor(settlement.status).withValues(alpha: 0.12),
                  ),
                  const Spacer(),
                  if (settlement.isPending && isReceiver) ...[
                    TextButton(
                      onPressed: () => controller.rejectPayment(settlement.id),
                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.confirmPayment(settlement.id),
                      child: const Text('Confirm'),
                    ),
                  ],
                  if (settlement.isPending && isSender)
                    TextButton(
                      onPressed: () => controller.cancelPayment(settlement.id),
                      child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SettlementModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildSettlementCard(context, list[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settlements'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'All'),
              Obx(() {
                final count = controller.pendingSettlements.length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const Tab(text: 'Confirmed'),
              const Tab(text: 'Other'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return Center(child: Text(controller.errorMessage.value));
          }

          return TabBarView(
            children: [
              _buildList(context, controller.settlements, 'No payments recorded yet.'),
              _buildList(context, controller.pendingSettlements, 'No pending payments waiting for confirmation.'),
              _buildList(context, controller.confirmedSettlements, 'No confirmed payments yet.'),
              _buildList(context, controller.otherSettlements, 'No rejected or cancelled payments.'),
            ],
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.toNamed(AppRoutes.addSettlement, arguments: controller.groupId);
          },
          icon: const Icon(Icons.add),
          label: const Text('Record Payment'),
        ),
      ),
    );
  }
}
