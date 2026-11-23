import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase_service.dart';
import '../models/member_balance_model.dart';
import '../models/purchase_model.dart';
import 'purchase_repository.dart';

class BalanceRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  final PurchaseRepository _purchaseRepository = PurchaseRepository();

  CollectionReference<Map<String, dynamic>> _members(String groupId) {
    return _firestore.collection('groups').doc(groupId).collection('members');
  }

  Future<List<Map<String, dynamic>>> _getAllMembers(String groupId) async {
    final snapshot = await _members(groupId).get();

    return snapshot.docs.map((doc) {
      return {'userId': doc.id, ...doc.data()};
    }).toList();
  }

  List<MemberBalanceModel> calculateBalances({
    required List<Map<String, dynamic>> members,
    required List<PurchaseModel> purchases,
  }) {
    final paidAmounts = <String, int>{};
    final shareAmounts = <String, int>{};

    final memberDetails = <String, Map<String, dynamic>>{};

    for (final member in members) {
      final userId = member['userId'] as String;

      memberDetails[userId] = member;
      paidAmounts[userId] = 0;
      shareAmounts[userId] = 0;
    }

    // Include historical users even if their member document
    // is unavailable. Their names may be displayed as Former member.
    for (final purchase in purchases) {
      paidAmounts.putIfAbsent(purchase.paidBy, () => 0);
      shareAmounts.putIfAbsent(purchase.paidBy, () => 0);

      // The person who paid receives credit for the full purchase.
      paidAmounts[purchase.paidBy] =
          paidAmounts[purchase.paidBy]! + purchase.amountPaise;

      // Each participant is responsible for their recorded share.
      for (final entry in purchase.splitAmounts.entries) {
        shareAmounts.putIfAbsent(entry.key, () => 0);

        shareAmounts[entry.key] = shareAmounts[entry.key]! + entry.value;
      }
    }

    final allUserIds = {...paidAmounts.keys, ...shareAmounts.keys};

    final balances = allUserIds.map((userId) {
      final member = memberDetails[userId];

      final paid = paidAmounts[userId] ?? 0;
      final share = shareAmounts[userId] ?? 0;

      return MemberBalanceModel(
        userId: userId,
        fullName: member?['fullName'] as String? ?? 'Former member',
        email: member?['email'] as String? ?? '',
        totalPaidPaise: paid,
        totalSharePaise: share,
        netBalancePaise: paid - share,
      );
    }).toList();

    balances.sort((a, b) {
      return b.netBalancePaise.compareTo(a.netBalancePaise);
    });

    return balances;
  }

  Stream<List<MemberBalanceModel>> watchBalances(String groupId) async* {
    try {
      final members = await _getAllMembers(groupId);

      await for (final purchases in _purchaseRepository.watchPurchases(
        groupId,
      )) {
        yield calculateBalances(members: members, purchases: purchases);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Gracefully exit stream when user logs out
        return;
      }
      rethrow;
    } catch (_) {
      return;
    }
  }
}
