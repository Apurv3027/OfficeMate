import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/purchase_repository.dart';
import '../../../data/models/purchase_model.dart';
import '../../../app/routes/app_routes.dart';

class PurchasesView extends StatelessWidget {
  const PurchasesView({super.key});

  String formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  @override
  Widget build(BuildContext context) {
    final String groupId = Get.arguments as String;
    final repository = Get.find<PurchaseRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: StreamBuilder<List<PurchaseModel>>(
        stream: repository.watchPurchases(groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load purchases.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Purchases Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start recording your shared office food and beverage expenses.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final total = purchases.fold<int>(
            0,
            (sum, purchase) => sum + purchase.amountPaise,
          );

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Total Purchases'),
                  subtitle: Text('${purchases.length} recorded purchases'),
                  trailing: Text(
                    formatAmount(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(
                          purchase.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Paid by ${purchase.paidByName}\n'
                          '${DateFormat('dd MMM yyyy').format(purchase.purchasedAt)}'
                          ' • ${purchase.participantIds.length} participants',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          formatAmount(purchase.amountPaise),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.purchaseDetails,
                            arguments: {
                              'groupId': groupId,
                              'purchaseId': purchase.id,
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(AppRoutes.addPurchase, arguments: groupId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Purchase'),
      ),
    );
  }
}
