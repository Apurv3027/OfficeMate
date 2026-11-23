import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_service.dart';
import '../models/purchase_model.dart';

class PurchaseRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login to continue.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _purchases(String groupId) {
    return _firestore.collection('groups').doc(groupId).collection('purchases');
  }

  DocumentReference<Map<String, dynamic>> _member(
    String groupId,
    String userId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId);
  }

  Future<List<String>> _validateMembers({
    required String groupId,
    required List<String> participantIds,
    required String paidBy,
  }) async {
    final ids = {...participantIds, paidBy};

    if (ids.isEmpty || participantIds.isEmpty) {
      throw Exception('Select at least one participant.');
    }

    if (ids.length > 50) {
      throw Exception('A purchase can include at most 50 members.');
    }

    final snapshots = await Future.wait(
      ids.map((id) => _member(groupId, id).get()),
    );

    for (var i = 0; i < snapshots.length; i++) {
      final snapshot = snapshots[i];

      if (!snapshot.exists || snapshot.data()?['isActive'] != true) {
        throw Exception('One or more selected members are no longer active.');
      }
    }

    return ids.toList();
  }

  Map<String, int> calculateEqualSplit({
    required int amountPaise,
    required List<String> participantIds,
  }) {
    if (participantIds.isEmpty) {
      throw Exception('Select at least one participant.');
    }

    if (amountPaise <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    final baseAmount = amountPaise ~/ participantIds.length;
    final remainder = amountPaise % participantIds.length;

    final splits = <String, int>{};

    for (int i = 0; i < participantIds.length; i++) {
      splits[participantIds[i]] = baseAmount + (i < remainder ? 1 : 0);
    }

    return splits;
  }

  Future<String> addPurchase({
    required String groupId,
    required String title,
    required String description,
    required int amountPaise,
    required String paidBy,
    required String paidByName,
    required List<String> participantIds,
    required Map<String, int> splitAmounts,
    required String splitType,
    required DateTime purchasedAt,
  }) async {
    if (title.trim().length < 2) {
      throw Exception('Enter a valid purchase title.');
    }

    if (amountPaise <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    if (splitType != 'equal' && splitType != 'custom') {
      throw Exception('Invalid split type.');
    }

    final uniqueParticipants = participantIds.toSet().toList();

    if (uniqueParticipants.length != participantIds.length) {
      throw Exception('Duplicate participants are not allowed.');
    }

    await _validateMembers(
      groupId: groupId,
      participantIds: uniqueParticipants,
      paidBy: paidBy,
    );

    if (splitAmounts.keys
        .toSet()
        .difference(uniqueParticipants.toSet())
        .isNotEmpty) {
      throw Exception('Invalid participant split.');
    }

    if (splitAmounts.values.any((amount) => amount < 0)) {
      throw Exception('Split amounts cannot be negative.');
    }

    final totalSplit = splitAmounts.values.fold<int>(
      0,
      (totalSum, amount) => totalSum + amount,
    );

    if (splitAmounts.length != uniqueParticipants.length ||
        totalSplit != amountPaise ||
        uniqueParticipants.any((id) => !splitAmounts.containsKey(id))) {
      throw Exception('Participant shares must equal the purchase total.');
    }

    if (splitType == 'equal') {
      final expected = calculateEqualSplit(
        amountPaise: amountPaise,
        participantIds: uniqueParticipants,
      );

      for (final id in uniqueParticipants) {
        if (splitAmounts[id] != expected[id]) {
          throw Exception('Invalid equal split amounts.');
        }
      }
    }

    final userId = _uid;

    final groupRef = _firestore.collection('groups').doc(groupId);
    final purchaseRef = _purchases(groupId).doc();

    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
      final creatorMember = await transaction.get(_member(groupId, userId));
      final payerMember = await transaction.get(_member(groupId, paidBy));

      if (!groupSnapshot.exists || groupSnapshot.data()?['isActive'] != true) {
        throw Exception('This group is unavailable.');
      }

      if (!creatorMember.exists || creatorMember.data()?['isActive'] != true) {
        throw Exception('You are not an active group member.');
      }

      if (!payerMember.exists || payerMember.data()?['isActive'] != true) {
        throw Exception('The selected payer is not active.');
      }

      transaction.set(purchaseRef, {
        'title': title.trim(),
        'description': description.trim(),
        'amountPaise': amountPaise,
        'paidBy': paidBy,
        'paidByName': paidByName,
        'participantIds': uniqueParticipants,
        'splitAmounts': splitAmounts,
        'splitType': splitType,
        'purchasedAt': Timestamp.fromDate(purchasedAt),
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return purchaseRef.id;
  }

  Stream<List<PurchaseModel>> watchPurchases(String groupId) {
    return _purchases(groupId)
        .orderBy('purchasedAt', descending: true)
        .snapshots()
        .handleError((error) {
          // Gracefully suppress permission-denied errors that fire when the user logs out
          if (error is FirebaseException && error.code == 'permission-denied') {
            return;
          }
          throw error;
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PurchaseModel.fromJson(doc.id, doc.data());
          }).toList();
        });
  }

  Future<PurchaseModel?> getPurchase({
    required String groupId,
    required String purchaseId,
  }) async {
    final snapshot = await _purchases(groupId).doc(purchaseId).get();

    if (!snapshot.exists) return null;

    return PurchaseModel.fromJson(snapshot.id, snapshot.data()!);
  }
}
