import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/fees/controllers/fee_plans_controller.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/features/fees/widgets/create_edit_fee_plan_dialog.dart';

class FeePlansView extends StatefulWidget {
  const FeePlansView({super.key});

  @override
  State<FeePlansView> createState() => _FeePlansViewState();
}

class _FeePlansViewState extends State<FeePlansView> {
  late final FeePlansController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FeePlansController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<FeePlansController>(
      controller: _controller,
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fee Plans',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Define and manage pricing structures for your academy.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    if (ctrl.canCreate)
                      AppPrimaryButton(
                        onPressed: () => _showCreatePlanDialog(context),
                        label: 'Create Fee Plan',
                        icon: Icons.add_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Content
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (ctrl.busy) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (ctrl.plans.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 260,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: ctrl.plans.length,
                        itemBuilder: (context, index) {
                          return _FeePlanCard(plan: ctrl.plans[index], controller: ctrl);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_outlined, size: 64, color: cs.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No Fee Plans Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You must create at least one fee plan before adding classes or students.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            onPressed: () => _showCreatePlanDialog(context),
            label: 'Create First Plan',
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    CreateEditFeePlanDialog.show(context, controller: _controller);
  }
}

class _FeePlanCard extends StatelessWidget {
  const _FeePlanCard({required this.plan, required this.controller});
  final FeePlan plan;
  final FeePlansController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r24,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ScopeBadge(scope: plan.scope),
                        if (plan.planType == FeePlanType.package) ...[
                          const SizedBox(width: 8),
                          _PackageBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              AppActionMenu(
                actions: [
                  AppActionItem(
                    label: 'Edit Plan',
                    icon: Icons.edit_outlined,
                    type: AppActionType.edit,
                    onTap: () => CreateEditFeePlanDialog.show(context, 
                      controller: controller, plan: plan),
                  ),
                  if (controller.canDelete)
                    AppActionItem(
                      label: 'Delete Plan',
                      icon: Icons.delete_outline_rounded,
                      type: AppActionType.delete,
                      onTap: () => _confirmDelete(context),
                    ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _AmountInfo(
                label: 'Admission',
                amount: plan.admissionFee,
                currency: plan.currency,
              ),
              const SizedBox(width: 32),
              _AmountInfo(
                label: plan.planType == FeePlanType.monthly ? 'Monthly Fee' : 'Total Course Fee',
                amount: plan.planType == FeePlanType.monthly ? plan.monthlyFee : plan.totalCourseFee,
                currency: plan.currency,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                plan.planType == FeePlanType.monthly ? Icons.event_note_rounded : Icons.timer_outlined, 
                size: 16, 
                color: cs.onSurfaceVariant
              ),
              const SizedBox(width: 8),
              Text(
                plan.planType == FeePlanType.monthly 
                    ? 'Due Day: ${plan.monthlyDueDay}'
                    : 'Duration: ${plan.durationMonths ?? 1} Months',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusIndicator(active: plan.isActive),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee Plan?'),
        content: const Text('This will permanently remove the fee plan. This action cannot be undone and will fail if students are assigned to this plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await controller.deletePlan(plan.id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Failed to delete plan')),
        );
      }
    }
  }
}

class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.scope});
  final String scope;

  @override
  Widget build(BuildContext context) {
    final isClass = scope == 'class';
    final cs = Theme.of(context).colorScheme;
    final color = isClass ? cs.primary : cs.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        scope.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({required this.label, required this.amount, required this.currency});
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          active ? 'ACTIVE' : 'INACTIVE',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = cs.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PACKAGE',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
