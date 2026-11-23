import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase_service.dart';
import '../models/member_balance_model.dart';
import '../models/purchase_model.dart';
import '../models/settlement_model.dart';
import 'purchase_repository.dart';
import 'settlement_repository.dart';

class BalanceRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  final PurchaseRepository _purchaseRepository = PurchaseRepository();

  final SettlementRepository _settlementRepository = SettlementRepository();

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
    required List<SettlementModel> settlements,
  }) {
    final paid = <String, int>{};
    final shares = <String, int>{};
    final sent = <String, int>{};
    final received = <String, int>{};

    final memberDetails = <String, Map<String, dynamic>>{};

    for (final member in members) {
      final id = member['userId'] as String;
      memberDetails[id] = member;
    }

    for (final purchase in purchases) {
      paid[purchase.paidBy] =
          (paid[purchase.paidBy] ?? 0) + purchase.amountPaise;

      for (final entry in purchase.splitAmounts.entries) {
        shares[entry.key] = (shares[entry.key] ?? 0) + entry.value;
      }
    }

    // Only confirmed settlements change financial balances.
    for (final settlement in settlements) {
      if (!settlement.isConfirmed) continue;

      sent[settlement.fromUserId] =
          (sent[settlement.fromUserId] ?? 0) + settlement.amountPaise;

      received[settlement.toUserId] =
          (received[settlement.toUserId] ?? 0) + settlement.amountPaise;
    }

    final allUserIds = <String>{
      ...memberDetails.keys,
      ...paid.keys,
      ...shares.keys,
      ...sent.keys,
      ...received.keys,
    };

    final result = allUserIds.map((userId) {
      final totalPaid = paid[userId] ?? 0;
      final totalShare = shares[userId] ?? 0;
      final totalSent = sent[userId] ?? 0;
      final totalReceived = received[userId] ?? 0;

      final member = memberDetails[userId];

      return MemberBalanceModel(
        userId: userId,
        fullName: member?['fullName'] as String? ?? 'Former member',
        email: member?['email'] as String? ?? '',
        totalPaidPaise: totalPaid,
        totalSharePaise: totalShare,
        totalSentPaise: totalSent,
        totalReceivedPaise: totalReceived,
        netBalancePaise: totalPaid - totalShare + totalSent - totalReceived,
      );
    }).toList();

    result.sort((a, b) => b.netBalancePaise.compareTo(a.netBalancePaise));

    return result;
  }

  Stream<List<MemberBalanceModel>> watchBalances(String groupId) async* {
    final members = await _getAllMembers(groupId);

    final purchasesStream = _purchaseRepository.watchPurchases(groupId);

    final settlementsStream = _settlementRepository.watchSettlements(groupId);

    // Combine both real-time streams.
    List<PurchaseModel> latestPurchases = [];
    List<SettlementModel> latestSettlements = [];

    var hasPurchases = false;
    var hasSettlements = false;

    final controller = StreamController<List<MemberBalanceModel>>();

    late final StreamSubscription<List<PurchaseModel>> purchaseSubscription;

    late final StreamSubscription<List<SettlementModel>> settlementSubscription;

    void emitIfReady() {
      if (!hasPurchases || !hasSettlements) return;

      controller.add(
        calculateBalances(
          members: members,
          purchases: latestPurchases,
          settlements: latestSettlements,
        ),
      );
    }

    purchaseSubscription = purchasesStream.listen((value) {
      latestPurchases = value;
      hasPurchases = true;
      emitIfReady();
    }, onError: controller.addError);

    settlementSubscription = settlementsStream.listen((value) {
      latestSettlements = value;
      hasSettlements = true;
      emitIfReady();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await purchaseSubscription.cancel();
      await settlementSubscription.cancel();
    };

    yield* controller.stream;
  }
}
