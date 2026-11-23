import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../../core/services/firebase_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;

  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Current authenticated user
  User? get currentUser => _auth.currentUser;

  // Authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user
  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    await user.updateDisplayName(fullName.trim());

    final now = DateTime.now();

    final userModel = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      password: password.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

    return credential;
  }

  // Login user
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // Ensure user profile exists
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      final now = DateTime.now();

      final userModel = UserModel(
        uid: user.uid,
        fullName: user.displayName ?? 'OfficeMate User',
        email: user.email ?? email.trim(),
        password: password.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson());
    }

    return credential;
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromJson(doc.data()!);
  }

  // Forgot password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
