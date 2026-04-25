import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/features/expenses/controllers/expenses_controller.dart';
import 'package:educore/src/features/expenses/models/expense.dart';
import 'package:educore/src/features/expenses/widgets/expense_dialog.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  late final ExpensesController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = ExpensesController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddExpense() {
    if (!_controller.canAdd) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseDialog(controller: _controller),
    );
  }

  void _showEditExpense(Expense expense) {
    if (!_controller.canEdit) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExpenseDialog(
        controller: _controller,
        expense: expense,
      ),
    );
  }

  Future<void> _confirmDelete(Expense expense) async {
    if (!_controller.canDelete) return;
    final confirmed = await AppDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
    );

    if (confirmed == true) {
      await _controller.deleteExpense(expense.id);
      if (mounted) {
        AppToasts.showSuccess(context, message: 'Expense deleted successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<ExpensesController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (controller.busy && controller.filteredExpenses.isEmpty && controller.totalExpenses == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        final size = screenSizeForWidth(MediaQuery.of(context).size.width);
        final isCompact = size == ScreenSize.compact;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, controller, isCompact),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildKPIs(context, controller, isCompact),
                      const SizedBox(height: 32),
                      _buildFilterBar(context, controller),
                      const SizedBox(height: 24),
                      _buildExpenseList(context, controller, isCompact),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ExpensesController controller, bool isCompact) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 32, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Track expenses and auto-calculate P/L',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (controller.canAdd)
            AppButton(
              label: 'Add Expense',
              icon: Icons.add_rounded,
              onPressed: _showAddExpense,
            ),
        ],
      ),
    );
  }

  Widget _buildKPIs(BuildContext context, ExpensesController controller, bool isCompact) {
    final format = NumberFormat.currency(symbol: '\$');
    final profitLossColor = controller.netProfitLoss >= 0 ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    
    return AppKpiGrid(
      columns: isCompact ? 1 : 4,
      items: [
        KpiCardData(
          label: 'Total Expenses',
          value: format.format(controller.totalExpenses),
          icon: Icons.money_off_rounded,
          gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
        ),
        KpiCardData(
          label: 'This Month Expenses',
          value: format.format(controller.thisMonthExpenses),
          icon: Icons.calendar_today_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        KpiCardData(
          label: 'Total Revenue',
          value: format.format(controller.totalRevenue),
          icon: Icons.attach_money_rounded,
          gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        KpiCardData(
          label: 'Net Profit / Loss',
          value: '${controller.netProfitLoss > 0 ? '+' : ''}${format.format(controller.netProfitLoss)}',
          icon: controller.netProfitLoss >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          gradient: [profitLossColor, profitLossColor.withValues(alpha: 0.8)],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, ExpensesController controller) {
    final cs = Theme.of(context).colorScheme;
    final categories = ['All', 'Salaries', 'Rent', 'Electricity', 'Internet', 'Maintenance', 'Transport', 'Marketing', 'Misc'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: AppDropdown<String>(
              label: 'Category',
              showLabel: false,
              compact: true,
              value: controller.filterCategory ?? 'All',
              items: categories,
              itemLabel: (c) => c,
              onChanged: (val) {
                if (val == 'All') {
                  controller.setFilters(category: null);
                } else {
                  controller.setFilters(category: val);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: AppDropdown<DateFilterPreset>(
              label: 'Period',
              showLabel: false,
              compact: true,
              value: controller.datePreset,
              items: DateFilterPreset.values,
              itemLabel: (d) => switch (d) {
                DateFilterPreset.all => 'All Time',
                DateFilterPreset.today => 'Today',
                DateFilterPreset.last7Days => 'Last 7 Days',
                DateFilterPreset.last30Days => 'Last 30 Days',
                DateFilterPreset.custom => 'Custom Range',
              },
              onChanged: (val) async {
                if (val == DateFilterPreset.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: controller.filterStartDate != null && controller.filterEndDate != null
                      ? DateTimeRange(start: controller.filterStartDate!, end: controller.filterEndDate!)
                      : null,
                    builder: (context, child) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                            maxHeight: 520,
                          ),
                          child: Dialog(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: child,
                          ),
                        ),
                      );
                    },
                  );
                  if (range != null) {
                    controller.setDatePreset(val!, range: range);
                  }
                } else if (val != null) {
                  controller.setDatePreset(val);
                }
              },
            ),
          ),
          const Spacer(),
          if (controller.filterCategory != null || controller.filterStartDate != null)
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, ExpensesController controller, bool isCompact) {
    final expenses = controller.filteredExpenses;
    if (expenses.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No expenses found',
        description: 'No expenses match the current criteria or none have been added yet.',
      );
    }

    final cs = Theme.of(context).colorScheme;
    final format = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: cs.errorContainer.withValues(alpha: 0.5),
              foregroundColor: cs.error,
              child: const Icon(Icons.money_off_rounded, size: 20),
            ),
            title: Text(
              expense.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(expense.date),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  format.format(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.error,
                  ),
                ),
                const SizedBox(width: 16),
                AppActionMenu(
                  actions: [
                    if (controller.canEdit)
                      AppActionItem(
                        label: 'Edit',
                        icon: Icons.edit_rounded,
                        type: AppActionType.edit,
                        onTap: () => _showEditExpense(expense),
                      ),
                    if (controller.canDelete)
                      AppActionItem(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        type: AppActionType.delete,
                        onTap: () => _confirmDelete(expense),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
