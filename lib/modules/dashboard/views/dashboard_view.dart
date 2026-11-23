import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../authentication/controllers/auth_controller.dart';

class DashboardView extends GetView<AuthController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OfficeMate'),
        actions: [
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.currentUser.value;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 42),
                ),

                const SizedBox(height: 20),

                Text(
                  'Welcome, ${user?.fullName ?? "OfficeMate User"}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                const Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Your OfficeMate account is ready!',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Group management will be implemented in Phase 3.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.groups);
                  },
                  icon: const Icon(Icons.groups),
                  label: const Text('My Groups'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
