import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/core/ui/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

enum FeatureMenuAction { edit, toggle, move }

@immutable
class FeatureRowAction {
  const FeatureRowAction(this.action, this.featureId);

  final FeatureMenuAction action;
  final String featureId;
}

class FeatureList extends StatelessWidget {
  const FeatureList({
    super.key,
    required this.items,
    required this.onAction,
    required this.onToggle,
  });

  final List<FeatureFlag> items;
  final ValueChanged<FeatureRowAction> onAction;
  final ValueChanged<(String, bool)> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            const AppEmptyState(
              title: 'No Features Found',
              description: 'System capabilities and modules will be registered here.',
              icon: Icons.tune_rounded,
            )
          else
            ..._rows(items),
        ],
      ),
    );
  }

  List<Widget> _rows(List<FeatureFlag> items) {
    return [
      const _Header(),
      const SizedBox(height: 8),
      for (var i = 0; i < items.length; i++)
        _FeatureRow(
          index: i,
          item: items[i],
          onAction: onAction,
          onToggle: onToggle,
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: AppRadii.r12,
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
        child: const Row(
          children: [
            Expanded(flex: 20, child: Text('Feature')),
            Expanded(flex: 12, child: Text('Key')),
            Expanded(flex: 20, child: Text('Description')),
            Expanded(flex: 10, child: Text('Status')),
            SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatefulWidget {
  const _FeatureRow({
    required this.index,
    required this.item,
    required this.onAction,
    required this.onToggle,
  });

  final int index;
  final FeatureFlag item;
  final ValueChanged<FeatureRowAction> onAction;
  final ValueChanged<(String, bool)> onToggle;

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final zebra = widget.index.isOdd
        ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
        : cs.surface;
    final bg = _hovered ? cs.primary.withValues(alpha: 0.040) : zebra;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.r12,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 20,
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(
                item.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                item.description.isEmpty ? '-' : item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusPill(active: item.isActive),
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<FeatureMenuAction>(
                  tooltip: 'Actions',
                  onSelected: (value) =>
                      widget.onAction(FeatureRowAction(value, item.id)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: FeatureMenuAction.edit,
                      child: Text('Edit feature'),
                    ),
                    PopupMenuItem(
                      value: FeatureMenuAction.toggle,
                      child: Text(item.isActive ? 'Disable' : 'Enable'),
                    ),
                    const PopupMenuItem(
                      value: FeatureMenuAction.move,
                      child: Text('Move to group'),
                    ),
                  ],
                  child: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: item.isActive,
              onChanged: (v) => widget.onToggle((item.id, v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
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
