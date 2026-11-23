import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_service.dart';
import '../models/settlement_model.dart';

class SettlementRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login to continue.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _settlements(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('settlements');
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

  Future<void> createSettlement({
    required String groupId,
    required String toUserId,
    required int amountPaise,
    required String note,
  }) async {
    final fromUserId = _uid;

    if (fromUserId == toUserId) {
      throw Exception('You cannot pay yourself.');
    }

    if (amountPaise <= 0) {
      throw Exception('Enter a valid payment amount.');
    }

    if (amountPaise > 100000000000) {
      throw Exception('Payment amount is too large.');
    }

    final settlementRef = _settlements(groupId).doc();

    await _firestore.runTransaction((transaction) async {
      final groupRef = _firestore.collection('groups').doc(groupId);

      final groupSnapshot = await transaction.get(groupRef);
      final senderSnapshot = await transaction.get(
        _member(groupId, fromUserId),
      );
      final receiverSnapshot = await transaction.get(
        _member(groupId, toUserId),
      );

      if (!groupSnapshot.exists || groupSnapshot.data()?['isActive'] != true) {
        throw Exception('Group is unavailable.');
      }

      if (!senderSnapshot.exists ||
          senderSnapshot.data()?['isActive'] != true) {
        throw Exception('Your group membership is inactive.');
      }

      if (!receiverSnapshot.exists ||
          receiverSnapshot.data()?['isActive'] != true) {
        throw Exception('Receiver is not an active group member.');
      }

      transaction.set(settlementRef, {
        'fromUserId': fromUserId,
        'fromUserName': senderSnapshot.data()?['fullName'] ?? '',
        'toUserId': toUserId,
        'toUserName': receiverSnapshot.data()?['fullName'] ?? '',
        'amountPaise': amountPaise,
        'note': note.trim(),
        'status': 'pending',
        'createdBy': fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'confirmedAt': null,
        'rejectedAt': null,
        'cancelledAt': null,
      });
    });
  }

  Future<void> _changeStatus({
    required String groupId,
    required String settlementId,
    required String newStatus,
  }) async {
    final settlementRef = _settlements(groupId).doc(settlementId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(settlementRef);

      if (!snapshot.exists) {
        throw Exception('Settlement not found.');
      }

      final data = snapshot.data()!;
      final currentUser = _uid;

      if (data['status'] != 'pending') {
        throw Exception('This payment is no longer pending.');
      }

      if (newStatus == 'confirmed' || newStatus == 'rejected') {
        if (data['toUserId'] != currentUser) {
          throw Exception(
            'Only the receiver can confirm or reject this payment.',
          );
        }
      } else if (newStatus == 'cancelled') {
        if (data['fromUserId'] != currentUser) {
          throw Exception('Only the sender can cancel this payment.');
        }
      }

      final update = <String, dynamic>{'status': newStatus};

      if (newStatus == 'confirmed') {
        update['confirmedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'rejected') {
        update['rejectedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'cancelled') {
        update['cancelledAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(settlementRef, update);
    });
  }

  Future<void> confirmSettlement({
    required String groupId,
    required String settlementId,
  }) {
    return _changeStatus(
      groupId: groupId,
      settlementId: settlementId,
      newStatus: 'confirmed',
    );
  }

  Future<void> rejectSettlement({
    required String groupId,
    required String settlementId,
  }) {
    return _changeStatus(
      groupId: groupId,
      settlementId: settlementId,
      newStatus: 'rejected',
    );
  }

  Future<void> cancelSettlement({
    required String groupId,
    required String settlementId,
  }) {
    return _changeStatus(
      groupId: groupId,
      settlementId: settlementId,
      newStatus: 'cancelled',
    );
  }

  Stream<List<SettlementModel>> watchSettlements(String groupId) {
    return _settlements(
      groupId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SettlementModel.fromJson(doc.id, doc.data());
      }).toList();
    });
  }
}
