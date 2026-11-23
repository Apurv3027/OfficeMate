import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OfficeMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadGroups,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadGroups,
        child: Obx(() {
          if (controller.isLoading.value && controller.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.isNotEmpty && controller.groups.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 160),
                Center(child: Text(controller.errorMessage.value)),
                Center(
                  child: TextButton(
                    onPressed: controller.loadGroups,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            );
          }

          if (controller.groups.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 100),
                Icon(Icons.groups_outlined, size: 70),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Create a group or join an existing group to start tracking expenses.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Welcome to OfficeMate!',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Manage your shared office expenses in one place.'),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Groups',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.groups);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ...controller.groups.map((group) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      group.description.isEmpty
                          ? 'Office expense group'
                          : group.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Get.toNamed(AppRoutes.groupDetails, arguments: group);
                    },
                  ),
                );
              }),

              const SizedBox(height: 16),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _quickAction(
                icon: Icons.add_circle_outline,
                title: 'Create Group',
                onTap: () {
                  Get.toNamed(AppRoutes.createGroup);
                },
              ),

              _quickAction(
                icon: Icons.group_add_outlined,
                title: 'Join Group',
                onTap: () {
                  Get.toNamed(AppRoutes.groups);
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
