import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/settlement_controller.dart';
import '../../../data/models/settlement_model.dart';
import '../../../app/routes/app_routes.dart';

class SettlementsView extends GetView<SettlementController> {
  const SettlementsView({super.key});

  String formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Widget settlementCard(SettlementModel settlement) {
    final currentUid = controller.currentUserId;

    final isReceiver = settlement.toUserId == currentUid;

    final isSender = settlement.fromUserId == currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${settlement.fromUserName} → ${settlement.toUserName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatAmount(settlement.amountPaise),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (settlement.note.isNotEmpty) Text(settlement.note),

            if (settlement.createdAt != null)
              Text(
                DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(settlement.createdAt!),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

            const SizedBox(height: 10),

            Row(
              children: [
                Chip(
                  label: Text(settlement.status.toUpperCase()),
                  backgroundColor: statusColor(
                    settlement.status,
                  ).withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: statusColor(settlement.status)),
                ),
                const Spacer(),

                if (settlement.isPending && isReceiver) ...[
                  TextButton(
                    onPressed: () {
                      controller.rejectPayment(settlement.id);
                    },
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.confirmPayment(settlement.id);
                    },
                    child: const Text('Confirm'),
                  ),
                ],

                if (settlement.isPending && isSender)
                  TextButton(
                    onPressed: () {
                      controller.cancelPayment(settlement.id);
                    },
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }

        if (controller.settlements.isEmpty) {
          return const Center(child: Text('No payments recorded yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.settlements.length,
          itemBuilder: (context, index) {
            return settlementCard(controller.settlements[index]);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.addSettlement, arguments: controller.groupId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }
}
