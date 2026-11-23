import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase_service.dart';
import '../models/report_summary_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  Future<ReportSummaryModel> getGroupReport({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final endExclusive = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    final groupRef = _firestore.collection('groups').doc(groupId);

    final results = await Future.wait([
      groupRef
          .collection('purchases')
          .where(
            'purchasedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('purchasedAt', isLessThan: Timestamp.fromDate(endExclusive))
          .get(),

      groupRef
          .collection('settlements')
          .where(
            'confirmedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('confirmedAt', isLessThan: Timestamp.fromDate(endExclusive))
          .get(),

      groupRef.collection('members').get(),
    ]);

    final purchaseSnapshot = results[0];

    final settlementSnapshot = results[1];

    final memberSnapshot = results[2];

    int totalExpense = 0;
    int totalConfirmedSettlements = 0;

    final Map<String, int> paidByMember = {};
    final Map<String, int> sharesByMember = {};
    final Map<String, String> memberNames = {};
    final Map<String, int> dailyExpenses = {};

    for (final memberDoc in memberSnapshot.docs) {
      final data = memberDoc.data();

      memberNames[memberDoc.id] =
          data['fullName'] as String? ?? 'Unknown Member';
    }

    for (final purchaseDoc in purchaseSnapshot.docs) {
      final data = purchaseDoc.data();

      final amount = _toInt(data['amountPaise']);
      final paidBy = data['paidBy'] as String? ?? '';
      final paidByName = data['paidByName'] as String? ?? 'Unknown';

      totalExpense += amount;

      if (paidBy.isNotEmpty) {
        paidByMember[paidBy] = (paidByMember[paidBy] ?? 0) + amount;

        memberNames.putIfAbsent(paidBy, () => paidByName);
      }

      final splitAmounts = data['splitAmounts'] as Map<String, dynamic>? ?? {};

      for (final entry in splitAmounts.entries) {
        final userId = entry.key;
        final share = _toInt(entry.value);

        sharesByMember[userId] = (sharesByMember[userId] ?? 0) + share;
      }

      final purchasedAt = data['purchasedAt'];

      if (purchasedAt is Timestamp) {
        final date = purchasedAt.toDate();
        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailyExpenses[dayKey] = (dailyExpenses[dayKey] ?? 0) + amount;
      }
    }

    for (final settlementDoc in settlementSnapshot.docs) {
      final data = settlementDoc.data();

      if (data['status'] == 'confirmed') {
        totalConfirmedSettlements += _toInt(data['amountPaise']);
      }
    }

    return ReportSummaryModel(
      totalExpensePaise: totalExpense,
      totalPurchases: purchaseSnapshot.docs.length,
      totalConfirmedSettlementPaise: totalConfirmedSettlements,
      paidByMember: paidByMember,
      sharesByMember: sharesByMember,
      memberNames: memberNames,
      dailyExpenses: dailyExpenses,
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
