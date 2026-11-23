import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/group_controller.dart';

class GroupsView extends GetView<GroupController> {
  const GroupsView({super.key});

  Future<void> _openCreateGroup() async {
    final result = await Get.toNamed(AppRoutes.createGroup);
    if (result == true) {
      controller.loadGroups();
    }
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Join a Group'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invitation Code',
            hintText: 'Enter 8-character code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isJoining.value
                  ? null
                  : () {
                      controller.joinGroup(codeController.text);
                    },
              child: controller.isJoining.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            onPressed: controller.loadGroups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Groups Yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a group or join one using an invitation code.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openCreateGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                  ),
                  TextButton(
                    onPressed: _showJoinDialog,
                    child: const Text('Join Existing Group'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadGroups,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.groups.length} Groups',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _showJoinDialog,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...controller.groups.map(
                (group) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      group.description.isEmpty
                          ? 'No description'
                          : group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.toNamed(AppRoutes.groupDetails, arguments: group);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }
}
