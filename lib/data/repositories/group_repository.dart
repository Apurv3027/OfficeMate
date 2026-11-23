import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_service.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('groupInvites');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please login to continue.');
    }
    return user.uid;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> createGroup({
    required String name,
    required String description,
    required String fullName,
    required String email,
  }) async {
    final uid = _uid;

    for (int attempt = 0; attempt < 5; attempt++) {
      final inviteCode = _generateInviteCode();

      final inviteRef = _invites.doc(inviteCode);
      final groupRef = _groups.doc();
      final memberRef = groupRef.collection('members').doc(uid);

      try {
        await _firestore.runTransaction((transaction) async {
          final inviteSnapshot = await transaction.get(inviteRef);

          if (inviteSnapshot.exists) {
            throw Exception('INVITE_CODE_COLLISION');
          }

          transaction.set(groupRef, {
            'name': name.trim(),
            'description': description.trim(),
            'inviteCode': inviteCode,
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          transaction.set(memberRef, {
            'userId': uid,
            'fullName': fullName,
            'email': email,
            'role': 'admin',
            'joinedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          transaction.set(inviteRef, {
            'groupId': groupRef.id,
            'createdBy': uid,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        return groupRef.id;
      } catch (e) {
        if (e.toString().contains('INVITE_CODE_COLLISION')) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Unable to generate an invitation code. Try again.');
  }

  Future<List<GroupModel>> getMyGroups() async {
    final uid = _uid;

    final membershipSnapshot = await _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .get();

    final groupIds = membershipSnapshot.docs
        .where((doc) => doc.data()['isActive'] == true)
        .map((doc) => doc.reference.parent.parent!.id)
        .toSet();

    if (groupIds.isEmpty) return [];

    final snapshots = await Future.wait(
      groupIds.map((groupId) => _groups.doc(groupId).get()),
    );

    final groups = <GroupModel>[];

    for (final snapshot in snapshots) {
      if (snapshot.exists && snapshot.data() != null) {
        final group = GroupModel.fromJson(snapshot.id, snapshot.data()!);

        if (group.isActive) {
          groups.add(group);
        }
      }
    }

    groups.sort((a, b) {
      return (b.createdAt ?? DateTime(2000)).compareTo(
        a.createdAt ?? DateTime(2000),
      );
    });

    return groups;
  }

  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final snapshot = await _groups
        .doc(groupId)
        .collection('members')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => GroupMemberModel.fromJson(doc.data()))
        .toList();
  }

  Future<String> joinGroup(String inviteCode) async {
    final uid = _uid;
    final code = inviteCode.trim().toUpperCase();

    if (code.isEmpty) {
      throw Exception('Please enter an invitation code.');
    }

    final inviteSnapshot = await _invites.doc(code).get();

    if (!inviteSnapshot.exists || inviteSnapshot.data()?['isActive'] != true) {
      throw Exception('Invalid or inactive invitation code.');
    }

    final groupId = inviteSnapshot.data()!['groupId'] as String;
    final groupRef = _groups.doc(groupId);
    final memberRef = groupRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(groupRef);
      final memberSnapshot = await transaction.get(memberRef);
      final latestInvite = await transaction.get(_invites.doc(code));

      if (!groupSnapshot.exists ||
          groupSnapshot.data()?['isActive'] != true ||
          !latestInvite.exists ||
          latestInvite.data()?['isActive'] != true) {
        throw Exception('This group invitation is no longer active.');
      }

      if (memberSnapshot.exists && memberSnapshot.data()?['isActive'] == true) {
        throw Exception('You are already a member of this group.');
      }

      final userSnapshot = await transaction.get(
        _firestore.collection('users').doc(uid),
      );

      if (!userSnapshot.exists) {
        throw Exception('Your user profile could not be found.');
      }

      final userData = userSnapshot.data()!;

      transaction.set(memberRef, {
        'userId': uid,
        'fullName': userData['fullName'] ?? '',
        'email': userData['email'] ?? '',
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    });

    return groupId;
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final uid = _uid;

    if (uid == memberId) {
      throw Exception('Use Leave Group to leave this group.');
    }

    final groupRef = _groups.doc(groupId);
    final adminRef = groupRef.collection('members').doc(uid);
    final memberRef = groupRef.collection('members').doc(memberId);

    await _firestore.runTransaction((transaction) async {
      final adminSnapshot = await transaction.get(adminRef);
      final memberSnapshot = await transaction.get(memberRef);

      if (!adminSnapshot.exists ||
          adminSnapshot.data()?['role'] != 'admin' ||
          adminSnapshot.data()?['isActive'] != true) {
        throw Exception('Only group admins can remove members.');
      }

      if (!memberSnapshot.exists ||
          memberSnapshot.data()?['isActive'] != true) {
        throw Exception('Member not found.');
      }

      transaction.update(memberRef, {'isActive': false});
    });
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _uid;

    final groupRef = _groups.doc(groupId);
    final memberRef = groupRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);

      if (!memberSnapshot.exists ||
          memberSnapshot.data()?['isActive'] != true) {
        throw Exception('You are not an active member of this group.');
      }

      if (memberSnapshot.data()?['role'] == 'admin') {
        throw Exception(
          'The group admin cannot leave yet. '
          'Transfer admin responsibility before leaving.',
        );
      }

      transaction.update(memberRef, {'isActive': false});
    });
  }
}
