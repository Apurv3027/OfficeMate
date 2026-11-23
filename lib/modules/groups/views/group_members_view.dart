import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/group_members_controller.dart';

class GroupMembersView extends GetView<GroupMembersController> {
  const GroupMembersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Members'),
        actions: [
          IconButton(
            onPressed: controller.loadMembers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.members.isEmpty) {
          return const Center(child: Text('No members found.'));
        }

        return RefreshIndicator(
          onRefresh: controller.loadMembers,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.members.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = controller.members[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(member.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text(member.isAdmin ? 'Admin' : 'Member')),
                      if (controller.isCurrentUserAdmin &&
                          !member.isAdmin &&
                          member.isActive)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              _confirmRemove(
                                context,
                                member.userId,
                                member.fullName,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove member'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmRemove(
    BuildContext context,
    String memberId,
    String memberName,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeMember(memberId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
