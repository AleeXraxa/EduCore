import 'package:educore/src/app/shell/app_shell.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboardView extends StatelessWidget {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Super Admin',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = screenSizeForWidth(constraints.maxWidth);
          final columns = switch (size) {
            ScreenSize.compact => 1,
            ScreenSize.medium => 2,
            ScreenSize.expanded => 4,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(),
                const SizedBox(height: 16),
                _KpiGrid(columns: columns),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Analytics',
                  subtitle: 'Revenue and institute growth at a glance.',
                ),
                const SizedBox(height: 12),
                Flex(
                  direction: size == ScreenSize.compact
                      ? Axis.vertical
                      : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AppCard(child: _RevenueChart())),
                    SizedBox(
                      width: size == ScreenSize.compact ? 0 : 16,
                      height: size == ScreenSize.compact ? 16 : 0,
                    ),
                    Expanded(child: AppCard(child: _GrowthChart())),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Operations',
                  subtitle: 'Recent activity and pending approvals.',
                ),
                const SizedBox(height: 12),
                Flex(
                  direction: size == ScreenSize.compact
                      ? Axis.vertical
                      : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AppCard(child: _ActivityList())),
                    SizedBox(
                      width: size == ScreenSize.compact ? 0 : 16,
                      height: size == ScreenSize.compact ? 16 : 0,
                    ),
                    Expanded(child: AppCard(child: _PendingPaymentsTable())),
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

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Admin Dashboard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage institutes, subscriptions, payments, and system health.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        AppCard(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                'Create Institute',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _KpiData('Total Institutes', '68', Icons.apartment_rounded),
      _KpiData('Active Subscriptions', '52', Icons.verified_rounded),
      _KpiData('Monthly Revenue', 'PKR 420k', Icons.payments_rounded),
      _KpiData('Pending Payments', '14', Icons.pending_actions_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: AppCard(child: _KpiCard(data: item)),
              )
          ],
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.icon, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Revenue Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              'Last 30 days',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Line chart',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institute Growth',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Bar chart',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _ActivityRow(
          icon: Icons.verified_rounded,
          title: 'Subscription approved',
          subtitle: 'Green Valley Academy • Standard Plan',
          time: '2m ago',
          tint: cs.primary,
        ),
        const SizedBox(height: 10),
        _ActivityRow(
          icon: Icons.payments_rounded,
          title: 'Payment verified',
          subtitle: 'Sunrise School • PKR 18,000',
          time: '18m ago',
          tint: cs.secondary,
        ),
        const SizedBox(height: 10),
        _ActivityRow(
          icon: Icons.block_rounded,
          title: 'Institute blocked',
          subtitle: 'Apex Institute • Policy violation',
          time: '1h ago',
          tint: cs.tertiary,
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _PendingPaymentsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Payments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              'View all',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TableHeader(),
        const SizedBox(height: 6),
        _TableRow(name: 'Green Valley', amount: 'PKR 18,000', status: 'Pending'),
        const SizedBox(height: 6),
        _TableRow(name: 'City School', amount: 'PKR 12,500', status: 'Review'),
        const SizedBox(height: 6),
        _TableRow(name: 'Apex Institute', amount: 'PKR 21,000', status: 'Pending'),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '1–3 of 12',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Institute',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            'Amount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 12),
          Text(
            'Status',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.name,
    required this.amount,
    required this.status,
  });

  final String name;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

