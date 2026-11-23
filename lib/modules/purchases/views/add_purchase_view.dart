import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/purchase_controller.dart';

class AddPurchaseView extends StatefulWidget {
  const AddPurchaseView({super.key});

  @override
  State<AddPurchaseView> createState() => _AddPurchaseViewState();
}

class _AddPurchaseViewState extends State<AddPurchaseView> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late final PurchaseController controller;

  DateTime purchasedAt = DateTime.now();

  @override
  void initState() {
    super.initState();

    controller = Get.find<PurchaseController>();
    controller.initialize(Get.arguments as String);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int get amountPaise {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || !amount.isFinite || amount <= 0) {
      return 0;
    }

    return (amount * 100).round();
  }

  String formatRupees(int paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }

  Future<void> selectPurchaseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: purchasedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        purchasedAt = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Purchase')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.members.isEmpty) {
          return const Center(child: Text('No active group members found.'));
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Purchase Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Name',
                  hintText: 'Example: Buttermilk',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Enter a valid purchase name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Example: Afternoon refreshments',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: '₹ ',
                  hintText: '80.00',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');

                  if (amount == null ||
                      !amount.isFinite ||
                      amount <= 0 ||
                      (amount * 100 - (amount * 100).round()).abs() >
                          0.000001) {
                    return 'Enter a valid amount with up to 2 decimals.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text('Who Paid?', style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: controller.paidBy.value.isEmpty
                    ? null
                    : controller.paidBy.value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: controller.members.map((member) {
                  return DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.fullName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.paidBy.value = value;
                  }
                },
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: controller.selectAllParticipants,
                    child: const Text('Select All'),
                  ),
                ],
              ),

              ...controller.members.map((member) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(member.fullName),
                  value: controller.selectedParticipants.contains(
                    member.userId,
                  ),
                  onChanged: (_) {
                    controller.toggleParticipant(member.userId);
                  },
                );
              }),

              const SizedBox(height: 20),

              Text(
                'Split Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 10),

              Obx(
                () => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'equal',
                      label: Text('Equal'),
                      icon: Icon(Icons.balance),
                    ),
                    ButtonSegment(
                      value: 'custom',
                      label: Text('Custom'),
                      icon: Icon(Icons.tune),
                    ),
                  ],
                  selected: {controller.splitType.value},
                  onSelectionChanged: (values) {
                    controller.changeSplitType(values.first);
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 16),

              if (controller.splitType.value == 'equal' &&
                  amountPaise > 0 &&
                  controller.selectedParticipants.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equal Split Preview',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...controller.getEqualSplits(amountPaise).entries.map((
                          entry,
                        ) {
                          final member = controller.members.firstWhere(
                            (m) => m.userId == entry.key,
                          );

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(member.fullName),
                            trailing: Text(formatRupees(entry.value)),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              if (controller.splitType.value == 'custom')
                ...controller.members
                    .where(
                      (member) => controller.selectedParticipants.contains(
                        member.userId,
                      ),
                    )
                    .map((member) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          key: ValueKey(
                            '${member.userId}_${controller.selectedParticipants.length}',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '${member.fullName} Share',
                            prefixText: '₹ ',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final amount = double.tryParse(value);
                            if (amount != null &&
                                amount.isFinite &&
                                amount >= 0 &&
                                (amount * 100 - (amount * 100).round()).abs() <
                                    0.000001) {
                              controller.updateCustomSplit(
                                member.userId,
                                (amount * 100).round(),
                              );
                            } else {
                              controller.customSplits.remove(member.userId);
                            }
                          },
                        ),
                      );
                    }),

              if (controller.splitType.value == 'custom')
                Obx(
                  () => Text(
                    'Allocated: ${formatRupees(controller.customSplitTotal)} / ${formatRupees(amountPaise)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.isCustomSplitValid(amountPaise)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: selectPurchaseDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'Purchase Date: ${DateFormat('dd MMM yyyy').format(purchasedAt)}',
                ),
              ),

              const SizedBox(height: 28),

              Obx(
                () => SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            controller.addPurchase(
                              title: _titleController.text,
                              description: _descriptionController.text,
                              amountPaise: amountPaise,
                              purchasedAt: purchasedAt,
                            );
                          },
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator()
                        : const Text('Save Purchase'),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
