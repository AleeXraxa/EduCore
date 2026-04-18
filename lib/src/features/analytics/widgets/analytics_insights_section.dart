import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/analytics/analytics_controller.dart';
import 'package:flutter/material.dart';

class AnalyticsInsightsSection extends StatelessWidget {
  const AnalyticsInsightsSection({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Insights',
          subtitle: 'Top performers and upcoming risk areas.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final vertical = size == ScreenSize.compact;
            return Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _TopInstitutesPanel(rows: snapshot.topInstitutes),
                  ),
                ),
                SizedBox(width: vertical ? 0 : 12, height: vertical ? 12 : 0),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: _UpcomingExpiriesPanel(rows: snapshot.upcomingExpiries),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
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
    );
  }
}

class _TopInstitutesPanel extends StatelessWidget {
  const _TopInstitutesPanel({required this.rows});

  final List<TopInstituteRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top performing institutes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Revenue contribution and growth signals.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        const _MiniTableHeader(cols: ['Institute', 'Revenue', 'Plan', 'Growth']),
        const SizedBox(height: 6),
        for (final r in rows) _TopInstituteRowView(row: r),
      ],
    );
  }
}

class _UpcomingExpiriesPanel extends StatelessWidget {
  const _UpcomingExpiriesPanel({required this.rows});

  final List<ExpiryRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming expiries',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Proactive view of renewals in the next days.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        const _MiniTableHeader(cols: ['Institute', 'Plan', 'Expiry', 'Days left']),
        const SizedBox(height: 6),
        for (final r in rows) _ExpiryRowView(row: r),
      ],
    );
  }
}

class _MiniTableHeader extends StatelessWidget {
  const _MiniTableHeader({required this.cols});
  final List<String> cols;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.75)),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
        child: Row(
          children: [
            Expanded(flex: 18, child: Text(cols[0])),
            Expanded(flex: 10, child: Text(cols[1])),
            Expanded(
              flex: 10,
              child: Align(alignment: Alignment.centerRight, child: Text(cols[2])),
            ),
            Expanded(
              flex: 10,
              child: Align(alignment: Alignment.centerRight, child: Text(cols[3])),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopInstituteRowView extends StatelessWidget {
  const _TopInstituteRowView({required this.row});
  final TopInstituteRow row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final up = row.growthPct >= 0;
    final fg = up ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final bg = (up ? const Color(0xFF16A34A) : const Color(0xFFEF4444))
        .withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 18,
            child: Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              _fmtMoney(row.revenuePkr),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              row.plan,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
                ),
                child: Text(
                  '${up ? '+' : ''}${row.growthPct.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryRowView extends StatelessWidget {
  const _ExpiryRowView({required this.row});
  final ExpiryRow row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final risk = row.daysLeft <= 7;
    final riskBg = const Color(0xFFF59E0B).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: risk ? riskBg : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 18,
            child: Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              row.plan,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _fmtDate(row.expiry),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${row.daysLeft}d',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: risk ? const Color(0xFFB45309) : cs.onSurface,
                    ),
              ),
            ),
          ),
        ],
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

String _fmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

