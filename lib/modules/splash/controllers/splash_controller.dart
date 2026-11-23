import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../modules/authentication/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthRepository _repository;
  final AuthController _authController;

  bool _isChecking = false;

  SplashController(this._repository, this._authController);

  @override
  void onInit() {
    super.onInit();
    checkAuthentication();
  }

  @override
  void onReady() {
    super.onReady();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Check current user synchronously or wait briefly for authStateChanges with timeout
      final user =
          _repository.currentUser ??
          await _repository.authStateChanges.first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );

      if (user != null) {
        final profile = await _repository
            .getUserProfile(user.uid)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (profile != null && profile.isActive) {
          _authController.currentUser.value = profile;

          Get.offAllNamed(AppRoutes.dashboard);
          return;
        }

        await _repository.logout();
      }

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
