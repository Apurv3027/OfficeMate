import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/purchase_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/purchase_repository.dart';

class PurchaseDetailsView extends StatelessWidget {
  const PurchaseDetailsView({super.key});

  String formatAmount(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;

    final groupId = args['groupId'] as String;
    final purchaseId = args['purchaseId'] as String;

    final purchaseRepository = Get.find<PurchaseRepository>();
    final groupRepository = GroupRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Details')),
      body: FutureBuilder<PurchaseModel?>(
        future: purchaseRepository.getPurchase(
          groupId: groupId,
          purchaseId: purchaseId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Purchase not found.'));
          }

          final purchase = snapshot.data!;

          return FutureBuilder(
            future: groupRepository.getGroupMembers(groupId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (memberSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load participants.'),
                );
              }

              final members = memberSnapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            purchase.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatAmount(purchase.amountPaise),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (purchase.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(purchase.description),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Paid By'),
                    subtitle: Text(purchase.paidByName),
                  ),

                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Purchase Date'),
                    subtitle: Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(purchase.purchasedAt),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.balance),
                    title: const Text('Split Method'),
                    subtitle: Text(
                      purchase.splitType == 'equal'
                          ? 'Equal Split'
                          : 'Custom Split',
                    ),
                  ),

                  const Divider(height: 32),

                  Text(
                    'Participant Shares',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 12),

                  ...purchase.participantIds.map((userId) {
                    final member = members.firstWhereOrNull(
                      (m) => m.userId == userId,
                    );

                    final share = purchase.splitAmounts[userId] ?? 0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            member?.fullName.isNotEmpty == true
                                ? member!.fullName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(member?.fullName ?? 'Former member'),
                        trailing: Text(
                          formatAmount(share),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
