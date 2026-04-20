import 'package:flutter/material.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/controllers/fees_controller.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/fees/widgets/collect_payment_dialog.dart';

class FeeDetailsDialog extends StatefulWidget {
  const FeeDetailsDialog({
    super.key,
    required this.fee,
    required this.controller,
    required this.onCollectPayment,
  });

  final Fee fee;
  final FeesController controller;
  final Future<void> Function({required double amount, required PaymentMethod method, String? note})? onCollectPayment;

  @override
  State<FeeDetailsDialog> createState() => _FeeDetailsDialogState();
}

class _FeeDetailsDialogState extends State<FeeDetailsDialog> {
  List<FeeTransaction>? _transactions;
  bool _isLoadingTxns = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final txns = await widget.controller.getFeeTransactions(widget.fee.id);
    if (!mounted) return;
    setState(() {
      _transactions = txns;
      _isLoadingTxns = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPaid = widget.fee.status == FeeStatus.paid;
    final remaining = (widget.fee.amount - widget.fee.paidAmount).clamp(0.0, double.infinity);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.fee.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(
                        label: widget.fee.type.name.toUpperCase(),
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: widget.fee.status.name.toUpperCase(),
                        color: isPaid ? Colors.green : (widget.fee.status == FeeStatus.partial ? Colors.blue : Colors.orange),
                      ),
                      if (widget.fee.isLocked) ...[
                        const SizedBox(width: 8),
                        const _Badge(
                          label: 'LOCKED',
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(32),
                shrinkWrap: true,
                children: [
                  _SummaryRow(
                    label: 'Total Amount',
                    value: NumberFormat.currency(symbol: 'Rs. ').format(widget.fee.amount),
                    isHighlight: true,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Amount Paid',
                    value: NumberFormat.currency(symbol: 'Rs. ').format(widget.fee.paidAmount),
                    valueColor: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Remaining Balance',
                    value: NumberFormat.currency(symbol: 'Rs. ').format(remaining),
                    valueColor: isPaid ? cs.onSurface : Colors.red,
                  ),
                  const SizedBox(height: 32),
                  
                  // Metadata
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MetaRow(label: 'Fee ID', value: widget.fee.id),
                        _MetaRow(label: 'Student', value: widget.fee.studentName ?? widget.fee.studentId),
                        _MetaRow(label: 'Class', value: widget.fee.className ?? widget.fee.classId),
                        if (widget.fee.month != null)
                          _MetaRow(label: 'Applicable Month', value: widget.fee.month!),
                        if (widget.fee.dueDate != null)
                          _MetaRow(
                            label: 'Due Date', 
                            value: DateFormat.yMMMd().format(widget.fee.dueDate!),
                          ),
                        _MetaRow(
                          label: 'Created',
                          value: DateFormat.yMMMd().format(widget.fee.createdAt),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Transactions List
                  Text(
                    'TRANSACTION HISTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingTxns)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_transactions == null || _transactions!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: const Text('No transactions recorded yet.'),
                    )
                  else
                    ..._transactions!.map((txn) => _TransactionTile(txn: txn)),
                  
                  const SizedBox(height: 32),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      if (!isPaid && widget.onCollectPayment != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Collect',
                            icon: Icons.payments_rounded,
                            onPressed: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => CollectPaymentDialog(
                                  fee: widget.fee,
                                  onCollect: widget.onCollectPayment!,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FeeTransaction txn;
  
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${txn.amount}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green),
              ),
              Text(
                DateFormat.yMMMd().add_jm().format(txn.collectedAt),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                txn.methodLabel,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (txn.note != null && txn.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              txn.note!,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
          ]
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            fontSize: isHighlight ? 14 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            fontSize: isHighlight ? 20 : 16,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
