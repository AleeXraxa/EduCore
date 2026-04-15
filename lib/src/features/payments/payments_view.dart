import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/payments/payments_controller.dart';
import 'package:educore/src/features/payments/widgets/payment_proof_dialog.dart';
import 'package:educore/src/features/payments/widgets/payments_table.dart';
import 'package:flutter/material.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  late final PaymentsController _controller;
  final _search = TextEditingController();
  PaymentsFilter _filter = PaymentsFilter.all;
  PaymentMethodFilter _method = PaymentMethodFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = PaymentsController();
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;

    return ControllerBuilder<PaymentsController>(
      controller: _controller,
      builder: (context, controller, _) {
        final kpis = controller.kpis;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review and manage all payment transactions.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 340,
                    height: toolbarHeight,
                    child: TextField(
                      controller: _search,
                      onChanged: controller.setQuery,
                      decoration: InputDecoration(
                        hintText: 'Search by institute name',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.r12,
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.r12,
                          borderSide: BorderSide(color: cs.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    height: toolbarHeight,
                    child: AppDropdown<PaymentsFilter>(
                      label: 'Status',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.filter_alt_rounded,
                      items: const [
                        PaymentsFilter.all,
                        PaymentsFilter.pending,
                        PaymentsFilter.approved,
                        PaymentsFilter.rejected,
                      ],
                      value: _filter,
                      hintText: 'Status',
                      itemLabel: (f) => switch (f) {
                        PaymentsFilter.all => 'All',
                        PaymentsFilter.pending => 'Pending',
                        PaymentsFilter.approved => 'Approved',
                        PaymentsFilter.rejected => 'Rejected',
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _filter = value);
                        controller.setFilter(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    height: toolbarHeight,
                    child: AppDropdown<PaymentMethodFilter>(
                      label: 'Method',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.payments_rounded,
                      items: const [
                        PaymentMethodFilter.all,
                        PaymentMethodFilter.jazzCash,
                        PaymentMethodFilter.easyPaisa,
                        PaymentMethodFilter.bank,
                      ],
                      value: _method,
                      hintText: 'Method',
                      itemLabel: (m) => switch (m) {
                        PaymentMethodFilter.all => 'All methods',
                        PaymentMethodFilter.jazzCash => 'JazzCash',
                        PaymentMethodFilter.easyPaisa => 'EasyPaisa',
                        PaymentMethodFilter.bank => 'Bank transfer',
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _method = value);
                        controller.setMethodFilter(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = screenSizeForWidth(constraints.maxWidth);
                  final columns = switch (size) {
                    ScreenSize.compact => 1,
                    ScreenSize.medium => 2,
                    ScreenSize.expanded => 4,
                  };

                  final items = [
                    KpiCardData(
                      label: 'Total Payments',
                      value: _fmtInt(kpis.total),
                      icon: Icons.receipt_long_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF6366F1)],
                    ),
                    KpiCardData(
                      label: 'Pending Payments',
                      value: _fmtInt(kpis.pending),
                      icon: Icons.pending_actions_rounded,
                      gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    KpiCardData(
                      label: 'Approved Payments',
                      value: _fmtInt(kpis.approved),
                      icon: Icons.verified_rounded,
                      gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
                    ),
                    KpiCardData(
                      label: 'Monthly Revenue',
                      value: _fmtMoney(kpis.monthRevenuePkr),
                      icon: Icons.payments_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    ),
                  ];

                  const gap = 12.0;
                  final totalGap = gap * (columns - 1);
                  final cardWidth = (constraints.maxWidth - totalGap) / columns;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final kpi in items)
                        SizedBox(
                          width: cardWidth,
                          child: KpiCard(data: kpi),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              PaymentsTable(
                items: controller.paged,
                resolveName: controller.getInstituteName,
                onViewProof: (payment) =>
                    PaymentProofDialog.show(context, payment: payment, instituteName: controller.getInstituteName(payment.academyId)),
                onAction: (action) async {
                  final p = controller.paged.firstWhere(
                    (e) => e.id == action.paymentId,
                  );

                  switch (action.action) {
                    case PaymentMenuAction.viewDetails:
                      if (!context.mounted) return;
                      PaymentProofDialog.show(context, payment: p, instituteName: controller.getInstituteName(p.academyId));
                      break;
                    case PaymentMenuAction.approve:
                      final ok = await _confirm(
                        context,
                        title: 'Approve payment?',
                        message:
                            'This will mark the payment as approved and unlock subscription flow.',
                        confirmLabel: 'Approve',
                        confirmColor: const Color(0xFF16A34A),
                      );
                      if (ok) controller.approve(action.paymentId);
                      break;
                    case PaymentMenuAction.reject:
                      final ok = await _confirm(
                        context,
                        title: 'Reject payment?',
                        message:
                            'This will mark the payment as rejected. The institute can resubmit proof.',
                        confirmLabel: 'Reject',
                        confirmColor: const Color(0xFFB91C1C),
                      );
                      if (ok) controller.reject(action.paymentId);
                      break;
                  }
                },
              ),
              const SizedBox(height: 12),
              _PaginationBar(
                total: controller.totalCount,
                page: controller.page,
                pageSize: controller.pageSize,
                onPrev: controller.prevPage,
                onNext: controller.nextPage,
              ),
              const SizedBox(height: 4),
              Text(
                'Tip: Pending payments are softly highlighted for faster review.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final int total;
  final int page;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final start = total == 0 ? 0 : (page * pageSize) + 1;
    final end = (page * pageSize + pageSize).clamp(0, total);

    return Row(
      children: [
        Text(
          '$start–$end of $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _PagerIcon(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous',
          onTap: onPrev,
        ),
        const SizedBox(width: 8),
        _PagerIcon(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PagerIcon extends StatefulWidget {
  const _PagerIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PagerIcon> createState() => _PagerIconState();
}

class _PagerIconState extends State<_PagerIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered ? cs.surfaceContainerHighest : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Icon(widget.icon, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

String _fmtMoney(int pkr) => 'PKR ${_fmtInt(pkr)}';

String _fmtInt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - 1 - i;
    b.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) b.write(',');
  }
  return b.toString().split('').reversed.join();
}
