import 'package:flutter/material.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

class CollectPaymentDialog extends StatefulWidget {
  final Fee fee;
  final Future<void> Function({required double amount, required PaymentMethod method, String? note}) onCollect;

  const CollectPaymentDialog({
    super.key,
    required this.fee,
    required this.onCollect,
  });

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  PaymentMethod _method = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.fee.remainingAmount.toStringAsFixed(0));
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collect Payment',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Recording payment for ${widget.fee.title}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Total Fee', value: 'Rs. ${widget.fee.amount}'),
                  _SummaryRow(label: 'Already Paid', value: 'Rs. ${widget.fee.paidAmount}', color: Colors.green),
                  const Divider(),
                  _SummaryRow(
                    label: 'Remaining', 
                    value: 'Rs. ${widget.fee.remainingAmount}', 
                    fontWeight: FontWeight.w900,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            AppTextField(
              controller: _amountCtrl,
              label: 'Received Amount (Rs.)',
              hintText: 'Enter amount',
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppDropdown<PaymentMethod>(
              label: 'Payment Method',
              value: _method,
              items: PaymentMethod.values,
              onChanged: (val) {
                if (val != null) setState(() => _method = val);
              },
              itemLabel: (v) => switch (v) {
                PaymentMethod.cash => 'Cash',
                PaymentMethod.bank => 'Bank Transfer',
                PaymentMethod.online => 'Online / Card',
              },
              prefixIcon: Icons.account_balance_wallet_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _noteCtrl,
              label: 'Transaction Note (Optional)',
              hintText: 'e.g., Check #1234, Bank of XYZ',
              prefixIcon: Icons.note_alt_outlined,
            ),
            
            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Confirm Payment',
              icon: Icons.check_circle_rounded,
              busy: _isLoading,
              onPressed: () async {
                final amountText = _amountCtrl.text.trim();
                if (amountText.isEmpty) {
                  AppToasts.showError(context, message: 'Please enter an amount');
                  return;
                }
                
                final amount = double.tryParse(amountText) ?? 0;
                if (amount <= 0) {
                  AppToasts.showError(context, message: 'Invalid amount');
                  return;
                }
                
                if (amount > widget.fee.remainingAmount + 0.01) {
                  AppToasts.showError(context, message: 'Amount exceeds remaining fee');
                  return;
                }
                
                setState(() => _isLoading = true);
                try {
                  await widget.onCollect(
                    amount: amount,
                    method: _method,
                    note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  debugPrint('CollectPaymentDialog: Error: $e');
                  if (context.mounted) {
                    setState(() => _isLoading = false);
                    AppToasts.showError(
                      context, 
                      message: 'Failed to collect payment: ${e.toString()}',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final FontWeight? fontWeight;

  const _SummaryRow({required this.label, required this.value, this.color, this.fontWeight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value, 
            style: TextStyle(
              fontSize: 14, 
              color: color, 
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
