import 'package:educore/src/app/shell/app_shell.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = screenSizeForWidth(constraints.maxWidth);
          final columns = switch (size) {
            ScreenSize.compact => 1,
            ScreenSize.medium => 2,
            ScreenSize.expanded => 4,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _KpiGrid(columns: columns),
                const SizedBox(height: 18),
                Flex(
                  direction: size == ScreenSize.compact
                      ? Axis.vertical
                      : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppCard(
                        child: _ChartPlaceholder(),
                      ),
                    ),
                    SizedBox(width: size == ScreenSize.compact ? 0 : 16, height: size == ScreenSize.compact ? 16 : 0),
                    Expanded(
                      flex: 2,
                      child: AppCard(
                        child: _ActivityFeed(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: _QuickActions(size: size),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _KpiData('Students', '1,248', Icons.people_alt_rounded),
      _KpiData('Revenue (MTD)', 'PKR 420k', Icons.payments_rounded),
      _KpiData('Attendance', '92%', Icons.fact_check_rounded),
      _KpiData('Profit (MTD)', 'PKR 155k', Icons.trending_up_rounded),
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

class _ChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Revenue trend',
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
              'Chart placeholder',
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

class _ActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.payments_rounded,
          title: 'Fee collected',
          subtitle: 'Ali Raza • Class 7',
          trailing: 'PKR 2,500',
          color: cs.primary,
        ),
        const SizedBox(height: 10),
        _ActivityItem(
          icon: Icons.fact_check_rounded,
          title: 'Attendance marked',
          subtitle: 'Class 5 • 42 students',
          trailing: 'Today',
          color: cs.tertiary,
        ),
        const SizedBox(height: 10),
        _ActivityItem(
          icon: Icons.person_add_alt_1_rounded,
          title: 'New admission',
          subtitle: 'Sara Khan • Class 3',
          trailing: '1h ago',
          color: cs.secondary,
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
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
          trailing,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.size});

  final ScreenSize size;

  @override
  Widget build(BuildContext context) {
    final actions = const [
      _ActionData('Add student', Icons.person_add_alt_1_rounded),
      _ActionData('Collect fee', Icons.payments_rounded),
      _ActionData('Mark attendance', Icons.fact_check_rounded),
      _ActionData('Add expense', Icons.receipt_long_rounded),
    ];

    final columns = switch (size) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 4,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final totalGap = gap * (columns - 1);
            final itemWidth = (constraints.maxWidth - totalGap) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: itemWidth,
                    child: AppCard(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(action.icon),
                          const SizedBox(width: 10),
                          Text(
                            action.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionData {
  const _ActionData(this.label, this.icon);
  final String label;
  final IconData icon;
}
