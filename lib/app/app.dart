import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class OfficeMateApp extends StatelessWidget {
  const OfficeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OfficeMate',
      debugShowCheckedModeBanner: false,

      initialBinding: InitialBinding(),

      initialRoute: AppRoutes.splash,

      getPages: AppPages.pages,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      defaultTransition: Transition.fadeIn,
    );
  }
}
