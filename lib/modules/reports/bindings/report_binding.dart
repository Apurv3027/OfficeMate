import 'package:get/get.dart';

import '../../../data/repositories/report_repository.dart';
import '../controllers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportRepository>(() => ReportRepository());

    Get.lazyPut<ReportController>(
      () => ReportController(Get.find<ReportRepository>()),
    );
  }
}
