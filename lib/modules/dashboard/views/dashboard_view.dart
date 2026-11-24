import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  String _formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM').format(date);
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
                    backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment', style: TextStyle(color: Colors.grey)),
                    Text(
                      transaction.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Initiator', style: TextStyle(color: Colors.grey)),
                    Text(
                      transaction.primaryUserName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date', style: TextStyle(color: Colors.grey)),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed(
                      AppRoutes.settlements,
                      arguments: controller.selectedGroupId.value,
                    );
                  },
                  child: const Text('View All Settlements'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OfficeMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.loadGroups();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadGroups,
        child: Obx(() {
          if (controller.isLoading.value && controller.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.isNotEmpty && controller.groups.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 160),
                Center(child: Text(controller.errorMessage.value)),
                Center(
                  child: TextButton(
                    onPressed: controller.loadGroups,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            );
          }

          final hasGroups = controller.groups.isNotEmpty;
          final selectedGroup = controller.selectedGroup;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome greeting
              Text(
                '${controller.greeting}, ${controller.userName} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your shared office expenses with ease.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Group Selector
              if (hasGroups) ...[
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'Active Group: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: controller.selectedGroupId.value.isEmpty
                                  ? null
                                  : controller.selectedGroupId.value,
                              items: controller.groups.map((group) {
                                return DropdownMenuItem<String>(
                                  value: group.id,
                                  child: Text(
                                    group.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectGroup(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Empty groups state
              if (!hasGroups) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.groups_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No groups joined yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create an office group or join via an invitation code to start tracking shared expenses.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Group Dashboard Content
              if (hasGroups && selectedGroup != null) ...[
                // Net Balance Card
                _buildNetBalanceCard(context),
                const SizedBox(height: 14),

                // Group Expenses & Pending Payments Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Group expenses',
                        amount: _formatAmount(controller.totalGroupExpensesPaise.value),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.purchases,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Pending payments',
                        amount: _formatAmount(controller.pendingSettlementsTotalPaise.value),
                        badgeText: controller.pendingSettlementsCount.value > 0
                            ? '${controller.pendingSettlementsCount.value} pending'
                            : null,
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.settlements,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Recent Transactions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.transactions,
                          arguments: selectedGroup.id,
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (controller.recentTransactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          'No transactions in this group yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                else
                  ...controller.recentTransactions.map((tx) {
                    return _buildTransactionCard(context, tx);
                  }),

                const SizedBox(height: 22),
              ],

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (hasGroups && selectedGroup != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.add_shopping_cart,
                        label: 'Add Purchase',
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.addPurchase,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'View Balances',
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.balances,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.payments_outlined,
                        label: 'Settlements',
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.settlements,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.history,
                        label: 'All History',
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.transactions,
                            arguments: selectedGroup.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Group Management Actions
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      context,
                      icon: Icons.add_circle_outline,
                      label: 'Create Group',
                      onTap: () => Get.toNamed(AppRoutes.createGroup),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      context,
                      icon: Icons.group_add_outlined,
                      label: 'Join Group',
                      onTap: () => Get.toNamed(AppRoutes.groups),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNetBalanceCard(BuildContext context) {
    final netPaise = controller.myNetBalancePaise.value;
    final isPositive = netPaise > 0;
    final isNegative = netPaise < 0;

    final color = isPositive
        ? Colors.green
        : isNegative
            ? Colors.red
            : Colors.blueGrey;

    final statusText = isPositive
        ? 'You will receive'
        : isNegative
            ? 'You need to pay'
            : 'You are all settled';

    final sign = isPositive ? '+' : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR NET BALANCE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$sign${_formatAmount(netPaise)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total paid',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(controller.myTotalPaidPaise.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.grey[300]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your share',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(controller.myTotalSharePaise.value),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx) {
    final isPurchase = tx.isPurchase;
    final isCurrentPayer = tx.primaryUserId == controller.currentUserId;
    final sign = (!isPurchase && tx.description.contains(controller.currentUserId)) ? '+' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isPurchase
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1),
          child: Icon(
            isPurchase ? Icons.shopping_bag_outlined : Icons.swap_horiz,
            color: isPurchase ? Colors.blue : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${_formatRelativeDate(tx.date)} · ${isCurrentPayer ? 'You' : tx.primaryUserName}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '$sign${_formatAmount(tx.amountPaise)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isPurchase ? Colors.black87 : Colors.green.shade700,
          ),
        ),
        onTap: () {
          if (isPurchase) {
            Get.toNamed(
              AppRoutes.purchaseDetails,
              arguments: {
                'groupId': controller.selectedGroupId.value,
                'purchaseId': tx.id,
              },
            );
          } else {
            _showSettlementDetails(context, tx);
          }
        },
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
