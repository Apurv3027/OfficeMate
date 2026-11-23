import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/group_model.dart';
import '../controllers/group_controller.dart';

class GroupDetailsView extends StatefulWidget {
  const GroupDetailsView({super.key});

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> {
  late final GroupController controller;
  late final GroupModel group;

  @override
  void initState() {
    super.initState();

    controller = Get.find<GroupController>();
    group = Get.arguments as GroupModel;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMembers(group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        actions: [
          IconButton(
            onPressed: () => controller.loadMembers(group.id),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.groups, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      group.description.isEmpty
                          ? 'No description'
                          : group.description,
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Invitation Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            group.inviteCode,
                            style: const TextStyle(
                              fontSize: 22,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy invitation code',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: group.inviteCode),
                            );

                            Get.snackbar(
                              'Copied',
                              'Invitation code copied.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                    const Text(
                      'Share this code with colleagues so they can join.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(AppRoutes.purchases, arguments: group.id);
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Purchases'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(AppRoutes.balances, arguments: group.id);
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('View Balances'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(AppRoutes.settlements, arguments: group.id);
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('View Settlements'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members (${controller.members.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Obx(
                  () => controller.isCurrentUserAdmin
                      ? const Chip(label: Text('Admin'))
                      : const Chip(label: Text('Member')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (controller.members.isEmpty)
              const Center(child: Text('No members found.')),
            ...controller.members.map(
              (member) => Card(
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
                      if (member.isAdmin) const Chip(label: Text('Admin')),
                      if (controller.isCurrentUserAdmin &&
                          member.userId != controller.currentUserId)
                        IconButton(
                          tooltip: 'Remove member',
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text('Remove Member'),
                                content: Text(
                                  'Remove ${member.fullName} from this group?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: Get.back,
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.removeMember(
                                        groupId: group.id,
                                        memberId: member.userId,
                                      );
                                    },
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Leave Group'),
                    content: const Text(
                      'Are you sure you want to leave this group?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: Get.back,
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          controller.leaveGroup(group.id);
                        },
                        child: const Text(
                          'Leave Group',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Leave Group'),
            ),
          ],
        );
      }),
    );
  }
}
