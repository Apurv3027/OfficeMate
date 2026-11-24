import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/settlement_helper.dart';
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

  void _onReceiverChanged(String? receiverId) {
    setState(() {
      selectedReceiver = receiverId;
    });

    if (receiverId != null) {
      controller.fetchOutstandingForReceiver(receiverId);
    }
  }

  void _setAmount(int paise) {
    setState(() {
      _amountController.text = (paise / 100).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Obx(() {
        final members = controller.members;
        final outstandingPaise = controller.selectedReceiverOutstandingPaise.value;
        final isLoadingDebt = controller.isLoadingOutstanding.value;
        final currentAmount = amountPaise;
        final remainingPaise = SettlementHelper.remainingAmount(
          outstandingPaise: outstandingPaise,
          confirmedPaymentsPaise: currentAmount,
        );

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Record a payment you have made to another group member.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

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
                onChanged: _onReceiverChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select the receiver.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              if (selectedReceiver != null) ...[
                if (isLoadingDebt)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Card(
                    color: outstandingPaise > 0
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'OUTSTANDING DEBT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: outstandingPaise > 0
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                              if (outstandingPaise > 0)
                                TextButton.icon(
                                  onPressed: () => _setAmount(outstandingPaise),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Pay Full Amount'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SettlementHelper.formatRupees(outstandingPaise),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: outstandingPaise > 0
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            outstandingPaise > 0
                                ? 'You owe this member ${SettlementHelper.formatRupees(outstandingPaise)}.'
                                : 'You have no outstanding debt with this member.',
                            style: TextStyle(
                              fontSize: 12,
                              color: outstandingPaise > 0
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                  hintText: '50.00',
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
                    return 'Enter a valid amount with up to 2 decimal places.';
                  }

                  final inputPaise = (amount * 100).round();
                  if (outstandingPaise > 0 &&
                      !SettlementHelper.isValidPayment(
                        paymentPaise: inputPaise,
                        outstandingPaise: outstandingPaise,
                      )) {
                    return 'Payment cannot exceed outstanding debt of ${SettlementHelper.formatRupees(outstandingPaise)}.';
                  }

                  return null;
                },
              ),

              if (outstandingPaise > 0 && currentAmount > 0) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Remaining debt after payment: ${SettlementHelper.formatRupees(remainingPaise)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remainingPaise == 0 ? Colors.green : Colors.grey[700],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Payment Note (Optional)',
                  hintText: 'Example: UPI transfer or Cash payment',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The receiver must confirm this payment before it updates group balances.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
