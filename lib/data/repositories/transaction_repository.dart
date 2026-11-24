import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  CollectionReference<Map<String, dynamic>> _purchases(
    String groupId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('purchases');
  }

  CollectionReference<Map<String, dynamic>> _settlements(
    String groupId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('settlements');
  }

  Future<List<TransactionModel>> getTransactions({
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = await Future.wait([
      _purchases(groupId).get(),
      _settlements(groupId).get(),
    ]);

    final purchaseSnapshot =
        results[0] as QuerySnapshot<Map<String, dynamic>>;

    final settlementSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;

    final transactions = <TransactionModel>[];

    for (final doc in purchaseSnapshot.docs) {
      final transaction =
          TransactionModel.fromPurchase(doc.id, doc.data());

      if (_isWithinDateRange(
        transaction.date,
        startDate,
        endDate,
      )) {
        transactions.add(transaction);
      }
    }

    for (final doc in settlementSnapshot.docs) {
      final transaction =
          TransactionModel.fromSettlement(doc.id, doc.data());

      if (_isWithinDateRange(
        transaction.date,
        startDate,
        endDate,
      )) {
        transactions.add(transaction);
      }
    }

    transactions.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return transactions;
  }

  bool _isWithinDateRange(
    DateTime date,
    DateTime? start,
    DateTime? end,
  ) {
    if (start != null && date.isBefore(start)) {
      return false;
    }

    if (end != null && date.isAfter(end)) {
      return false;
    }

    return true;
  }
}
