import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../modules/authentication/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthRepository>(AuthRepository(), permanent: true);

    Get.put<AuthController>(
      AuthController(Get.find<AuthRepository>()),
      permanent: true,
    );
  }
}
