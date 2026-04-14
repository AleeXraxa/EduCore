import 'package:flutter/material.dart';

class PlanStatusBadge extends StatelessWidget {
  const PlanStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = (active ? const Color(0xFF16A34A) : const Color(0xFF64748B))
        .withValues(alpha: 0.10);
    final fg = active ? const Color(0xFF15803D) : const Color(0xFF475569);
    final label = active ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
      ),
    );
  }
}

