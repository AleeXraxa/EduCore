import 'package:flutter/material.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';

class CollectPaymentDialog extends StatefulWidget {
  final Fee fee;
  final Function(double) onCollect;

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.fee.remainingAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
            
            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Confirm Payment',
              icon: Icons.check_circle_rounded,
              busy: _isLoading,
              onPressed: () async {
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                if (amount <= 0) return;
                
                setState(() => _isLoading = true);
                await widget.onCollect(amount);
                if (!context.mounted) return;
                Navigator.pop(context);
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
