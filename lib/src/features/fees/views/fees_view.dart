import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';

import 'package:educore/src/features/fees/controllers/fees_controller.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';

import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/fees/widgets/collect_payment_dialog.dart';
import 'package:educore/src/features/fees/widgets/generate_monthly_fees_dialog.dart';
import 'package:educore/src/features/fees/widgets/create_other_fee_dialog.dart';
import 'package:educore/src/features/fees/widgets/fee_details_dialog.dart';
import 'package:educore/src/features/fees/widgets/fee_document_dialog.dart';

import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/views/no_internet_view.dart';
import 'package:educore/src/core/ui/widgets/app_data_grid.dart';
import 'package:intl/intl.dart';

class FeesView extends StatefulWidget {
  const FeesView({super.key});

  @override
  State<FeesView> createState() => _FeesViewState();
}

class _FeesViewState extends State<FeesView>
    with SingleTickerProviderStateMixin {
  late final FeesController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = FeesController();
    _controller.loadInitialData();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('fee_view')) {
      return const AccessDeniedView(featureName: 'Fee Management');
    }

    return ControllerBuilder<FeesController>(
      controller: _controller,
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeesHeader(controller: controller),
              const Divider(height: 1),

              // Tabs for Fee Types
              Container(
                color: cs.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  onTap: (index) {
                    final type = switch (index) {
                      0 => FeeType.admission,
                      1 => FeeType.monthly,
                      2 => FeeType.package,
                      _ => FeeType.other,
                    };
                    controller.loadInitialData(type: type);
                  },
                  tabs: const [
                    Tab(text: 'Admission'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'Package'),
                    Tab(text: 'Other'),
                  ],
                ),
              ),

              // Status Filter Row
              Container(
                color: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'STATUS FILTER:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SegmentedButton<FeeStatus?>(
                      segments: const [
                        ButtonSegment(
                          value: null,
                          label: Text('All'),
                          icon: Icon(Icons.all_inclusive_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: FeeStatus.pending,
                          label: Text('Pending'),
                          icon: Icon(Icons.pending_actions_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: FeeStatus.paid,
                          label: Text('Paid'),
                          icon: Icon(Icons.check_circle_outline_rounded, size: 18),
                        ),
                      ],
                      selected: {controller.currentStatus},
                      onSelectionChanged: (val) {
                        controller.loadInitialData(status: val.first);
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedBackgroundColor: cs.primary,
                        selectedForegroundColor: cs.onPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Showing ${controller.fees.length} Records',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: controller.busy && controller.fees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.hasError && controller.fees.isEmpty
                        ? NoInternetView(
                            onRetry: () => controller.loadInitialData(),
                          )
                        : _FeesList(
                            fees: controller.fees,
                            controller: controller,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeesHeader extends StatelessWidget {
  const _FeesHeader({required this.controller});
  final FeesController controller;

  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService!;
    final cs = Theme.of(context).colorScheme;
    final stats = controller.stats;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fee Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const Spacer(),
              if (featureSvc.canAccess('fee_plan_manage'))
                FilledButton.icon(
                  onPressed: () => _showGenerateDialog(context),
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Generate Monthly Fees'),
                ),
              const SizedBox(width: 12),
              if (featureSvc.canAccess('fee_manage'))
                FilledButton.tonalIcon(
                  onPressed: () => _showCreateOtherFeeDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Manual Fee'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Grid
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  data: KpiCardData(
                    label: 'Total Collected',
                    value: controller.busy && stats['totalRevenue'] == 0.0
                        ? '---'
                        : NumberFormat.currency(
                            symbol: 'Rs. ',
                          ).format(stats['totalRevenue']),
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  data: KpiCardData(
                    label: 'Total Pending',
                    value: controller.busy && stats['totalPending'] == 0.0
                        ? '---'
                        : NumberFormat.currency(
                            symbol: 'Rs. ',
                          ).format(stats['totalPending']),
                    icon: Icons.pending_actions_rounded,
                    gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: KpiCard(
                  data: KpiCardData(
                    label: 'Monthly Growth',
                    value: '12.5%',
                    icon: Icons.trending_up_rounded,
                    gradient: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GenerateMonthlyFeesDialog(
        onGenerate: ({
          double? amount,
          required classId,
          required month,
          String? overrideReason,
          required title,
          dueDate,
        }) async {
          // STEP 1: Confirmation (Internal to dialog usually, but we handle feedback here)
          AppDialogs.showLoading(context, message: 'Generating records...');
          
          final count = await controller.generateMonthlyFees(
            context: context,
            classId: classId,
            month: month,
            amount: amount,
            overrideReason: overrideReason,
            title: title,
            dueDate: dueDate,
          );

          if (context.mounted) {
            AppDialogs.hideLoading(context);
            if (count > 0) {
              AppDialogs.showSuccess(
                context,
                title: 'Generation Complete',
                message: 'Successfully generated $count monthly fee records.',
              );
            } else if (count == 0) {
              AppDialogs.showInfo(
                context,
                title: 'No New Records',
                message: 'All students in this class already have a fee record for $month.',
              );
            } else {
              AppDialogs.showError(
                context,
                title: 'Process Failed',
                message: controller.error ?? 'Failed to generate monthly fees.',
              );
            }
          }
          return (count, controller.error);
        },
      ),
    );
  }

  void _showCreateOtherFeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateOtherFeeDialog(
        onCreate: (fee) => controller.createOtherFee(context, fee),
      ),
    );
  }
}

class _FeesList extends StatelessWidget {
  const _FeesList({required this.fees, required this.controller});
  final List<Fee> fees;
  final FeesController controller;

  @override
  Widget build(BuildContext context) {
    if (fees.isEmpty) {
      return const Center(
        child: Text('No fee records found for this category.'),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return AppDataGrid<Fee>(
      items: fees,
      columns: const [
        AppDataGridColumn(label: 'Record', flex: 3),
        AppDataGridColumn(label: 'Student', flex: 2),
        AppDataGridColumn(label: 'Amount', width: 140),
        AppDataGridColumn(label: 'Status', width: 140, center: true),
        AppDataGridColumn(label: 'Actions', width: 120),
      ],
      onSelectionChanged: (selected) {
        controller.clearSelection();
        for (final f in selected) {
          controller.toggleSelection(f.id);
        }
      },
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
          tooltip: 'Bulk Challan',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
          tooltip: 'Remind Selection',
        ),
      ],
      rowBuilder: (context, fee) {
        final isPaid = fee.status == FeeStatus.paid;
        return [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                  color: isPaid ? Colors.green : Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fee.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(fee.dueDate ?? fee.createdAt),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fee.studentName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                fee.className ?? '-',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rs. ${fee.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              if (fee.paidAmount > 0)
                Text(
                  'Paid: Rs. ${fee.paidAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          AppStatusPill(
            label: fee.status.name,
            color: _getStatusColor(fee.status),
          ),
          _actionCell(context, fee),
        ];
      },
    );
  }

  Color _getStatusColor(FeeStatus status) {
    return switch (status) {
      FeeStatus.paid => Colors.green,
      FeeStatus.partial => Colors.blue,
      FeeStatus.pending => Colors.orange,
    };
  }

  Widget _actionCell(BuildContext context, Fee fee) {
    final featureSvc = AppServices.instance.featureAccessService!;
    final isPaid = fee.status == FeeStatus.paid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isPaid && !fee.isLocked && featureSvc.canAccess('fee_collect'))
          IconButton(
            onPressed: () => _collectPayment(context, fee),
            icon: const Icon(Icons.payments_rounded, size: 20),
            color: Theme.of(context).colorScheme.primary,
            visualDensity: VisualDensity.compact,
          ),
        AppActionMenu(
          actions: [
            AppActionItem(
              label: 'View Details',
              icon: Icons.visibility_outlined,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => FeeDetailsDialog(
                    fee: fee,
                    controller: controller,
                    onCollectPayment: ({required amount, required method, note}) =>
                        controller.collectPayment(
                      context,
                      fee.id,
                      amount,
                      method: method,
                      note: note,
                    ),
                  ),
                );
              },
            ),
            if (!isPaid) ...[
              AppActionItem(
                label: 'Send WhatsApp Reminder',
                icon: Icons.send_rounded,
                onTap: () => controller.sendWhatsAppReminder(context, fee),
              ),
              AppActionItem(
                label: 'WhatsApp Message',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () async {
                  final msg = await AppDialogs.showInput(
                    context,
                    title: 'Message to ${fee.studentName}',
                    hintText: 'Type your message here...',
                    multiline: true,
                  );
                  if (msg != null && msg.trim().isNotEmpty) {
                    await controller.sendWhatsAppMessage(
                      context,
                      fee,
                      msg.trim(),
                    );
                  }
                },
              ),
              if (featureSvc.canAccess('challan_generate'))
                AppActionItem(
                  label: 'Generate Challan',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => FeeDocumentDialog(fee: fee, mode: 'challan'),
                  ),
                ),
            ],
            if (fee.paidAmount > 0 && featureSvc.canAccess('challan_generate'))
              AppActionItem(
                label: 'Generate Receipt',
                icon: Icons.task_alt_rounded,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => FeeDocumentDialog(fee: fee, mode: 'receipt'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _collectPayment(BuildContext context, Fee fee) {
    showDialog<double>(
      context: context,
      builder: (_) => CollectPaymentDialog(
        fee: fee,
        onCollect: ({required amount, required method, note}) async {
          await controller.collectPayment(context, fee.id, amount, method: method, note: note);
        },
      ),
    ).then((paidAmount) async {
      if (!context.mounted) return;
      final genReceipt = await AppDialogs.showConfirm(
        context,
        title: 'Payment Successful',
        message: 'Payment has been recorded. Would you like to generate a receipt now?',
        confirmLabel: 'Generate Receipt',
        cancelLabel: 'Later',
      );
      if (genReceipt == true && context.mounted) {
        showDialog(
          context: context,
          builder: (_) => FeeDocumentDialog(fee: fee, mode: 'receipt'),
        );
      }
    });
  }
}
