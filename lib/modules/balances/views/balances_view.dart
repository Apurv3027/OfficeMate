import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/balance_controller.dart';
import '../../../data/models/member_balance_model.dart';

class BalancesView extends GetView<BalanceController> {
  const BalancesView({super.key});

  String formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(MemberBalanceModel member) {
    final isPositive = member.netBalancePaise > 0;
    final isNegative = member.netBalancePaise < 0;

    final status = isPositive
        ? 'Gets back'
        : isNegative
        ? 'Owes'
        : 'Settled';

    final statusColor = isPositive
        ? Colors.green
        : isNegative
        ? Colors.red
        : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (member.email.isNotEmpty)
                        Text(
                          member.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(member.absoluteBalancePaise),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(color: Colors.grey)),
                Text(formatAmount(member.totalPaidPaise)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Share', style: TextStyle(color: Colors.grey)),
                Text(formatAmount(member.totalSharePaise)),
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
      appBar: AppBar(title: const Text('Group Balances')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.errorMessage.value),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.loadBalances,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.balances.isEmpty) {
          return const Center(
            child: Text(
              'No balance records yet.\nAdd a purchase to get started.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.loadBalances();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Group Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              _summaryCard(
                title: 'Total Group Expenses',
                amount: formatAmount(controller.totalGroupPaidPaise),
                icon: Icons.account_balance_wallet_outlined,
              ),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Members Should Receive',
                      amount: formatAmount(controller.totalReceivablePaise),
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  Expanded(
                    child: _summaryCard(
                      title: 'Members Owe',
                      amount: formatAmount(controller.totalPayablePaise),
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Individual Balances',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              ...controller.balances.map(_memberCard),

              const SizedBox(height: 20),

              if (controller.totalGroupPaidPaise !=
                  controller.totalGroupSharePaise)
                const Text(
                  'Balance calculation warning: total paid and total shares do not match. Please review your purchase records.',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        );
      }),
    );
  }
}
