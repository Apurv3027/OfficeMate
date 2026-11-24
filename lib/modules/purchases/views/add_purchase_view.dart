import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/expense_split_helper.dart';
import '../../../data/models/food_category_model.dart';
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

  final Map<String, TextEditingController> _customControllers = {};

  late final PurchaseController controller;

  DateTime purchasedAt = DateTime.now();

  String selectedCategoryId = 'buttermilk';
  String selectedSplitType = 'equal';
  Map<String, int> customSplitAmounts = {};

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
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get amountPaise {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    try {
      return ExpenseSplitHelper.rupeesToPaise(text);
    } catch (_) {
      return 0;
    }
  }

  void _syncCustomSplitsWithParticipants() {
    customSplitAmounts.removeWhere(
      (id, _) => !controller.selectedParticipants.contains(id),
    );
  }

  TextEditingController _getCustomController(String userId) {
    if (!_customControllers.containsKey(userId)) {
      _customControllers[userId] = TextEditingController();
    }
    return _customControllers[userId]!;
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

        final selectedParticipantIds = controller.selectedParticipants.toList();
        final currentAmountPaise = amountPaise;

        final totalSplitPaise = customSplitAmounts.values.fold<int>(
          0,
          (sum, amount) => sum + amount,
        );
        final remainingPaise = currentAmountPaise - totalSplitPaise;

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

              DropdownButtonFormField<String>(
                initialValue: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Food Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: FoodCategoryModel.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 10),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
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
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a purchase amount.';
                  }
                  try {
                    ExpenseSplitHelper.rupeesToPaise(value.trim());
                  } catch (e) {
                    return e.toString().replaceFirst('ArgumentError: ', '');
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
                    onPressed: () {
                      controller.selectAllParticipants();
                      _syncCustomSplitsWithParticipants();
                      setState(() {});
                    },
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
                    _syncCustomSplitsWithParticipants();
                    setState(() {});
                  },
                );
              }),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Split Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'equal',
                        label: Text('Equal Split'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                      ButtonSegment(
                        value: 'custom',
                        label: Text('Custom Split'),
                        icon: Icon(Icons.tune),
                      ),
                    ],
                    selected: {selectedSplitType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        selectedSplitType = selection.first;
                        controller.splitType.value = selection.first;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (selectedSplitType == 'equal' &&
                  currentAmountPaise > 0 &&
                  selectedParticipantIds.isNotEmpty)
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
                        ...() {
                          if (currentAmountPaise < selectedParticipantIds.length) {
                            return [
                              const Text(
                                'Amount must be at least 1 paise per participant.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ];
                          }
                          try {
                            final splits = ExpenseSplitHelper.calculateEqualSplit(
                              amountPaise: currentAmountPaise,
                              participantIds: selectedParticipantIds,
                            );

                            return splits.entries.map((entry) {
                              final member = controller.members.firstWhere(
                                (m) => m.userId == entry.key,
                              );

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(member.fullName),
                                trailing: Text(
                                  ExpenseSplitHelper.formatPaise(entry.value),
                                ),
                              );
                            }).toList();
                          } catch (e) {
                            return [
                              Text(
                                e.toString().replaceFirst('ArgumentError: ', ''),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ];
                          }
                        }(),
                      ],
                    ),
                  ),
                ),

              if (selectedSplitType == 'custom') ...[
                const SizedBox(height: 8),
                Text(
                  'Custom Shares',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...controller.members
                    .where(
                      (member) => selectedParticipantIds.contains(member.userId),
                    )
                    .map((member) {
                      final customController = _getCustomController(member.userId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          key: ValueKey('custom_${member.userId}'),
                          controller: customController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '${member.fullName} Share',
                            prefixText: '₹ ',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isEmpty) {
                              customSplitAmounts.remove(member.userId);
                            } else {
                              try {
                                final sharePaise = ExpenseSplitHelper.rupeesToPaise(
                                  trimmed,
                                );
                                customSplitAmounts[member.userId] = sharePaise;
                              } catch (_) {
                                customSplitAmounts.remove(member.userId);
                              }
                            }
                            setState(() {});
                          },
                        ),
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allocated: ${ExpenseSplitHelper.formatPaise(totalSplitPaise)} / ${ExpenseSplitHelper.formatPaise(currentAmountPaise)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: remainingPaise == 0
                              ? Colors.green
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining: ${ExpenseSplitHelper.formatPaise(remainingPaise)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: remainingPaise == 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

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

                            if (controller.selectedParticipants.isEmpty) {
                              Get.snackbar(
                                'Error',
                                'Select at least one participant.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            final participantIds =
                                controller.selectedParticipants.toList();
                            Map<String, int> finalSplitAmounts;

                            if (selectedSplitType == 'equal') {
                              try {
                                finalSplitAmounts =
                                    ExpenseSplitHelper.calculateEqualSplit(
                                  amountPaise: currentAmountPaise,
                                  participantIds: participantIds,
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Invalid Split',
                                  e.toString().replaceFirst(
                                    'ArgumentError: ',
                                    '',
                                  ),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                            } else {
                              final isValid =
                                  ExpenseSplitHelper.validateCustomSplit(
                                amountPaise: currentAmountPaise,
                                splitAmounts: customSplitAmounts,
                                participantIds: participantIds,
                              );

                              if (!isValid) {
                                Get.snackbar(
                                  'Invalid Split',
                                  'Participant shares must equal the purchase amount.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              finalSplitAmounts =
                                  Map<String, int>.from(customSplitAmounts);
                            }

                            final selectedCategory = FoodCategoryModel.findById(
                              selectedCategoryId,
                            );

                            controller.addPurchase(
                              title: _titleController.text,
                              description: _descriptionController.text,
                              amountPaise: currentAmountPaise,
                              purchasedAt: purchasedAt,
                              categoryId: selectedCategory.id,
                              categoryName: selectedCategory.name,
                              splitAmounts: finalSplitAmounts,
                              splitType: selectedSplitType,
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
