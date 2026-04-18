import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class FeatureGroupNav extends StatelessWidget {
  const FeatureGroupNav({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelect,
    required this.onSearch,
  });

  final List<String> groups;
  final String selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.soft(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Groups',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search groups',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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
          const SizedBox(height: 12),
          Expanded(
            child: groups.length <= 1
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No groups created yet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final g in groups)
                          _GroupItem(
                            label: g,
                            selected: g == selected,
                            onTap: () => onSelect(g),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupItem extends StatefulWidget {
  const _GroupItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GroupItem> createState() => _GroupItemState();
}

class _GroupItemState extends State<_GroupItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.10)
        : (_hovered ? cs.surfaceContainerHighest : Colors.transparent);
    final fg = widget.selected ? cs.primary : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hovered = v),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.folder_rounded, color: fg, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
