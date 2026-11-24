import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/balance_controller.dart';
import '../../../data/models/member_balance_model.dart';

class BalanceView extends GetView<BalanceController> {
  const BalanceView({super.key});

  String formatMoney(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Balances'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final balances = controller.balances;

        if (balances.isEmpty) {
          return const Center(
            child: Text('No balance records available.'),
          );
        }

        final currentBalance = controller.currentUserBalance;

        return RefreshIndicator(
          onRefresh: () async {
            controller.watchBalances();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (currentBalance != null)
                _buildCurrentUserCard(currentBalance),

              const SizedBox(height: 20),

              const Text(
                'Group Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _summaryCard(
                'Total Group Expenses',
                formatMoney(controller.totalGroupExpensePaise),
                Colors.blue,
              ),

              _summaryCard(
                'Total To Receive',
                formatMoney(controller.totalToReceivePaise),
                Colors.green,
              ),

              _summaryCard(
                'Total To Pay',
                formatMoney(controller.totalToPayPaise),
                Colors.red,
              ),

              const SizedBox(height: 20),

              const Text(
                'Member Balances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...balances.map(_buildMemberCard),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentUserCard(MemberBalanceModel balance) {
    final color = balance.shouldReceive
        ? Colors.green
        : balance.shouldPay
            ? Colors.red
            : Colors.grey;

    final status = balance.shouldReceive
        ? 'You should receive'
        : balance.shouldPay
            ? 'You need to pay'
            : 'You are settled';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Current Balance',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              formatMoney(balance.absoluteBalancePaise),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 24),
            _detailRow(
              'Total Paid',
              formatMoney(balance.totalPaidPaise),
            ),
            _detailRow(
              'Your Expense Share',
              formatMoney(balance.totalSharePaise),
            ),
            _detailRow(
              'Payments Sent',
              formatMoney(balance.totalSentPaise),
            ),
            _detailRow(
              'Payments Received',
              formatMoney(balance.totalReceivedPaise),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberBalanceModel balance) {
    final color = balance.shouldReceive
        ? Colors.green
        : balance.shouldPay
            ? Colors.red
            : Colors.grey;

    final status = balance.shouldReceive
        ? 'Should receive'
        : balance.shouldPay
            ? 'Should pay'
            : 'Settled';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            balance.fullName.isNotEmpty
                ? balance.fullName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(balance.fullName),
        subtitle: Text(status),
        trailing: Text(
          formatMoney(balance.absoluteBalancePaise),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String amount,
    Color color,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
