import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settlement_controller.dart';

class AddSettlementView extends StatefulWidget {
  const AddSettlementView({super.key});

  @override
  State<AddSettlementView> createState() => _AddSettlementViewState();
}

class _AddSettlementViewState extends State<AddSettlementView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late final SettlementController controller;

  String? selectedReceiver;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettlementController>();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get amountPaise {
    final value = double.tryParse(_amountController.text.trim());

    if (value == null || !value.isFinite || value <= 0) {
      return 0;
    }

    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Obx(() {
        final members = controller.members;

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Record a payment you have made to another group member.',
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: selectedReceiver,
                decoration: const InputDecoration(
                  labelText: 'Payment Received By',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: members
                    .where(
                      (member) => member.userId != controller.currentUserId,
                    )
                    .map((member) {
                      return DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text(member.fullName),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReceiver = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Select the receiver.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                  hintText: '30.00',
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
                    return 'Enter a valid amount.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Payment Note (Optional)',
                  hintText: 'Example: Cash payment for buttermilk expenses',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Payment confirmation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The receiver must confirm this payment before it changes group balances.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Obx(
                () => SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            controller.createSettlement(
                              toUserId: selectedReceiver!,
                              amountPaise: amountPaise,
                              note: _noteController.text,
                            );
                          },
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator()
                        : const Text('Record Payment'),
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
