import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/group_controller.dart';

class CreateGroupView extends GetView<GroupController> {
  const CreateGroupView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your office group',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invite your colleagues and start tracking '
                'shared food and beverage expenses.',
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Example: Office Friends',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Enter at least 3 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Example: Daily office refreshments',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              controller.createGroup(
                                name: nameController.text,
                                description: descriptionController.text,
                              );
                            }
                          },
                    child: controller.isCreating.value
                        ? const CircularProgressIndicator()
                        : const Text('Create Group'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
