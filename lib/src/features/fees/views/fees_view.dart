import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
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
  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Create Fee Entry', style: TextStyle(fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fee Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SegmentedButton<FeeType>(
              segments: const [
                ButtonSegment(value: FeeType.monthly, label: Text('Monthly')),
                ButtonSegment(value: FeeType.admission, label: Text('Admission')),
                ButtonSegment(value: FeeType.misc, label: Text('Misc')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) => setState(() => _selectedType = set.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _studentNameController,
              decoration: const InputDecoration(labelText: 'Student / Payer Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (PKR)', border: OutlineInputBorder()),
            ),
            if (_selectedType == FeeType.monthly) ...[
              const SizedBox(height: 12),
              const Text('Select Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [0, 1, 2, 3, 4, 5].map((i) {
                  final m = DateTime.now().add(Duration(days: -30 * i));
                  final val = DateFormat('MMMM yyyy').format(m);
                  return DropdownMenuItem(value: val, child: Text(val));
                }).toList(),
                onChanged: (val) => setState(() => _selectedMonth = val!),
              ),
            ],
            if (_selectedType == FeeType.misc) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount <= 0 || _studentNameController.text.isEmpty) return;

            String? error;
            if (_selectedType == FeeType.admission) {
              error = await widget.controller.createAdmissionFee(
                studentId: 'MOCK_ID', // In real app, pick from list
                studentName: _studentNameController.text,
                amount: amount,
              );
            } else if (_selectedType == FeeType.monthly) {
              error = await widget.controller.createMonthlyFee(
                studentId: 'MOCK_ID',
                studentName: _studentNameController.text,
                amount: amount,
                month: _selectedMonth,
              );
            } else {
              error = await widget.controller.createMiscFee(
                title: _studentNameController.text,
                description: _descController.text,
                amount: amount,
              );
            }

            if (error != null) {
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: cs.error));
              }
            } else {
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Create Entry'),
        ),
      ],
    );
  }
}
