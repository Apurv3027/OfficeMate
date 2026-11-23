import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController(this._repository);

  final isLoading = false.obs;

  final isPasswordVisible = false.obs;

  final currentUser = Rxn<UserModel>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Login
  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      final credential = await _repository.login(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      currentUser.value = await _repository.getUserProfile(uid);

      Get.offAllNamed(AppRoutes.dashboard);

      Get.snackbar(
        'Success',
        'Welcome back to OfficeMate!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthError(e.code));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Register
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final credential = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      currentUser.value = await _repository.getUserProfile(
        credential.user!.uid,
      );

      Get.offAllNamed(AppRoutes.dashboard);

      Get.snackbar(
        'Account Created',
        'Welcome to OfficeMate!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthError(e.code));
    } catch (e) {
      _showError('Unable to create account. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;

      await _repository.resetPassword(email);

      Get.snackbar(
        'Email Sent',
        'Check your email for the password reset link.',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthError(e.code));
    } catch (e) {
      _showError('Unable to send reset email.');
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;

      await _repository.logout();

      currentUser.value = null;

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _showError('Unable to logout. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
  }

  String _getAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'operation-not-allowed':
        return 'Email authentication is not enabled.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
