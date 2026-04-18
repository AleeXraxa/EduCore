import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';

import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/fees/controllers/fees_controller.dart';
import 'package:educore/src/features/fees/models/fee_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeesView extends StatefulWidget {
  const FeesView({super.key});

  @override
  State<FeesView> createState() => _FeesViewState();
}

class _FeesViewState extends State<FeesView> {
  late final FeesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FeesController();
    _controller.loadFees();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCollectFeeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CollectFeeDialog(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<FeesController>(
      controller: _controller,
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeesHeader(
                controller: controller,
                onCollectFee: _showCollectFeeDialog,
              ),
              const Divider(height: 1),
              Expanded(
                child: controller.busy
                    ? const Center(child: CircularProgressIndicator())
                    : _FeesContent(controller: controller),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeesHeader extends StatelessWidget {
  const _FeesHeader({required this.controller, required this.onCollectFee});
  final FeesController controller;
  final VoidCallback onCollectFee;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = screenSizeForWidth(MediaQuery.sizeOf(context).width) != ScreenSize.compact;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                  ),
                  Text(
                    'Structured student fees & misc income',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onCollectFee,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Fee Entry'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AppKpiGrid(
            columns: isDesktop ? 3 : 1,
            items: [
              KpiCardData(
                label: 'Collected (${controller.currentType.name.toUpperCase()})',
                value: 'Rs. ${NumberFormat('#,###').format(controller.totalCollected)}',
                icon: Icons.account_balance_wallet_rounded,
                gradient: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                trendText: 'This month',
                trendUp: true,
              ),
              KpiCardData(
                label: 'Pending (${controller.currentType.name.toUpperCase()})',
                value: 'Rs. ${NumberFormat('#,###').format(controller.totalPending)}',
                icon: Icons.pending_actions_rounded,
                gradient: [const Color(0xFFE11D48), const Color(0xFFBE123C)],
                trendText: 'Requires action',
                trendUp: false,
              ),
              KpiCardData(
                label: 'Recent Growth',
                value: '+Rs. 12,400',
                icon: Icons.trending_up_rounded,
                gradient: [cs.primary, cs.secondary],
                trendText: 'Last 7 days',
                trendUp: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SegmentedButton<FeeType>(
            segments: const [
              ButtonSegment(
                value: FeeType.monthly,
                label: Text('Monthly Fees'),
                icon: Icon(Icons.calendar_month_rounded, size: 18),
              ),
              ButtonSegment(
                value: FeeType.admission,
                label: Text('Admission Fees'),
                icon: Icon(Icons.how_to_reg_rounded, size: 18),
              ),
              ButtonSegment(
                value: FeeType.misc,
                label: Text('Misc / Others'),
                icon: Icon(Icons.more_horiz_rounded, size: 18),
              ),
            ],
            selected: {controller.currentType},
            onSelectionChanged: (set) => controller.setFeeType(set.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeesContent extends StatelessWidget {
  const _FeesContent({required this.controller});
  final FeesController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.filteredFees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No ${controller.currentType.name} records found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: controller.filteredFees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fee = controller.filteredFees[index];
        return _FeeRecordCard(
          fee: fee,
          onCollect: () => controller.collectFee(fee.id),
        );
      },
    );
  }
}

class _FeeRecordCard extends StatelessWidget {
  const _FeeRecordCard({required this.fee, required this.onCollect});
  final FeeRecord fee;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPaid = fee.status == FeeStatus.paid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isPaid ? Colors.teal : Colors.amber).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isPaid ? Colors.teal : Colors.amber,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  fee.type == FeeType.monthly
                      ? 'Monthly Fee • ${fee.month}'
                      : (fee.type == FeeType.admission
                          ? 'Admission Fee • ${fee.className ?? "N/A"}'
                          : 'Misc • ${fee.description ?? "Other Fee"}'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${NumberFormat('#,###').format(fee.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              if (isPaid && fee.paidAt != null)
                Text(
                  'Paid ${DateFormat('MMM d').format(fee.paidAt!)}',
                  style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'Pending',
                  style: TextStyle(color: cs.error, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(width: 24),
            IconButton.filledTonal(
              onPressed: onCollect,
              icon: const Icon(Icons.payments_rounded, size: 20),
              tooltip: 'Mark as Paid',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectFeeDialog extends StatefulWidget {
  const _CollectFeeDialog({required this.controller});
  final FeesController controller;

  @override
  State<_CollectFeeDialog> createState() => _CollectFeeDialogState();
}

class _CollectFeeDialogState extends State<_CollectFeeDialog> {
  FeeType _selectedType = FeeType.monthly;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _studentNameController = TextEditingController();
  bool _loading = false;

  final List<String> _months = List.generate(6, (i) {
    final m = DateTime.now().subtract(Duration(days: 30 * i));
    return DateFormat('MMMM yyyy').format(m);
  });
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0 || _studentNameController.text.trim().isEmpty) {
      AppToasts.showError(context, message: 'Please fill in all required fields.');
      return;
    }

    setState(() => _loading = true);
    String? error;
    if (_selectedType == FeeType.admission) {
      error = await widget.controller.createAdmissionFee(
        studentId: 'MOCK_ID',
        studentName: _studentNameController.text.trim(),
        amount: amount,
      );
    } else if (_selectedType == FeeType.monthly) {
      error = await widget.controller.createMonthlyFee(
        studentId: 'MOCK_ID',
        studentName: _studentNameController.text.trim(),
        amount: amount,
        month: _selectedMonth,
      );
    } else {
      error = await widget.controller.createMiscFee(
        title: _studentNameController.text.trim(),
        description: _descController.text.trim(),
        amount: amount,
      );
    }
    setState(() => _loading = false);

    if (!mounted) return;
    if (error != null) {
      AppToasts.showError(context, message: error);
    } else {
      AppToasts.showSuccess(context, message: 'Fee recorded successfully.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feeTypeLabels = {
      FeeType.monthly: 'Monthly',
      FeeType.admission: 'Admission',
      FeeType.misc: 'Misc / Other',
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadii.r12,
                    ),
                    child: Icon(Icons.payments_rounded, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Fee Entry',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Record a new payment against a student.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEE TYPE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<FeeType>(
                    style: SegmentedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.r12),
                    ),
                    segments: FeeType.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(feeTypeLabels[t]!),
                            ))
                        .toList(),
                    selected: {_selectedType},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedType = set.first),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _studentNameController,
                    label: 'Student / Payer Name',
                    hintText: 'e.g. Ali Hassan',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amountController,
                    label: 'Amount (PKR)',
                    hintText: '0.00',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  if (_selectedType == FeeType.monthly) ...[
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: 'Select Month',
                      items: _months,
                      value: _selectedMonth,
                      itemLabel: (m) => m,
                      prefixIcon: Icons.calendar_month_rounded,
                      onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                    ),
                  ],
                  if (_selectedType == FeeType.misc) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descController,
                      label: 'Description',
                      hintText: 'What is this payment for?',
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // ── Footer ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppPrimaryButton(
                    label: 'Record Payment',
                    icon: Icons.check_rounded,
                    onPressed: _loading ? null : _submit,
                    busy: _loading,
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

