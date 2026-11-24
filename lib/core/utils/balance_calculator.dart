import '../../data/models/group_member_model.dart';
import '../../data/models/purchase_model.dart';
import '../../data/models/settlement_model.dart';
import '../../data/models/member_balance_model.dart';

class BalanceCalculator {
  static List<MemberBalanceModel> calculate({
    required List<GroupMemberModel> members,
    required List<PurchaseModel> purchases,
    required List<SettlementModel> settlements,
  }) {
    final Map<String, int> totalPaid = {};
    final Map<String, int> totalShare = {};
    final Map<String, int> totalSent = {};
    final Map<String, int> totalReceived = {};

    // Initialize all members, including inactive members.
    // Historical balances must not disappear when someone leaves.
    for (final member in members) {
      totalPaid[member.userId] = 0;
      totalShare[member.userId] = 0;
      totalSent[member.userId] = 0;
      totalReceived[member.userId] = 0;
    }

    // Calculate purchase payments and expense shares.
    for (final purchase in purchases) {
      final payerId = purchase.paidBy;

      if (totalPaid.containsKey(payerId)) {
        totalPaid[payerId] =
            totalPaid[payerId]! + purchase.amountPaise;
      }

      for (final entry in purchase.splitAmounts.entries) {
        final userId = entry.key;
        final sharePaise = entry.value;

        if (totalShare.containsKey(userId)) {
          totalShare[userId] =
              totalShare[userId]! + sharePaise;
        }
      }
    }

    // Only confirmed settlements affect balances.
    for (final settlement in settlements) {
      if (settlement.status != 'confirmed') {
        continue;
      }

      final senderId = settlement.fromUserId;
      final receiverId = settlement.toUserId;
      final amountPaise = settlement.amountPaise;

      if (totalSent.containsKey(senderId)) {
        totalSent[senderId] =
            totalSent[senderId]! + amountPaise;
      }

      if (totalReceived.containsKey(receiverId)) {
        totalReceived[receiverId] =
            totalReceived[receiverId]! + amountPaise;
      }
    }

    // Calculate final balance for every member.
    final List<MemberBalanceModel> results = [];

    for (final member in members) {
      final paid = totalPaid[member.userId] ?? 0;
      final share = totalShare[member.userId] ?? 0;
      final sent = totalSent[member.userId] ?? 0;
      final received = totalReceived[member.userId] ?? 0;

      final netBalance = paid - share + sent - received;

      results.add(
        MemberBalanceModel(
          userId: member.userId,
          fullName: member.fullName,
          email: member.email,
          totalPaidPaise: paid,
          totalSharePaise: share,
          totalSentPaise: sent,
          totalReceivedPaise: received,
          netBalancePaise: netBalance,
        ),
      );
    }

    // Members who should receive money appear first.
    results.sort((a, b) {
      return b.netBalancePaise.compareTo(a.netBalancePaise);
    });

    return results;
  }
}
