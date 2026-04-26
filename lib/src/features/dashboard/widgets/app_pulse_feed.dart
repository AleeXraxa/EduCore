import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PulseActivityKind { enrollment, payment, test, general }

class PulseActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final PulseActivityKind kind;
  final String? amount;

  PulseActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.kind,
    this.amount,
  });
}

class AppPulseFeed extends StatelessWidget {
  const AppPulseFeed({
    super.key,
    required this.items,
    this.maxItems = 8,
  });

  final List<PulseActivityItem> items;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayItems = items..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final limitedItems = displayItems.take(maxItems).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, cs),
          if (limitedItems.isEmpty)
            _buildEmptyState(cs)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: limitedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _PulseItem(
                item: limitedItems[index],
                index: index,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _PulseDot(),
          const SizedBox(width: 16),
          Text(
            'INSTITUTE PULSE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
          ),
          const Spacer(),
          Text(
            'LIVE',
            style: TextStyle(
              color: cs.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.sensors_off_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Waiting for heartbeat...',
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 1.0 - _controller.value),
                blurRadius: 8 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseItem extends StatelessWidget {
  const _PulseItem({required this.item, required this.index});

  final PulseActivityItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('hh:mm a').format(item.timestamp);

    final (icon, color) = switch (item.kind) {
      PulseActivityKind.enrollment => (Icons.person_add_rounded, const Color(0xFF2563EB)),
      PulseActivityKind.payment => (Icons.payments_rounded, const Color(0xFF10B981)),
      PulseActivityKind.test => (Icons.quiz_rounded, const Color(0xFFF59E0B)),
      PulseActivityKind.general => (Icons.notifications_rounded, cs.primary),
    };

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.amount != null)
                      Text(
                        item.amount!,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
