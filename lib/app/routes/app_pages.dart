import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.home, page: () => const HomePlaceholder()),
  ];
}

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OfficeMate')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 64),
            SizedBox(height: 16),
            Text(
              'Welcome to OfficeMate!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Food & Beverage Expense Management',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
