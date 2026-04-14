import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class Topbar extends StatelessWidget {
  const Topbar({super.key, required this.title, required this.onToggleSidebar});

  final String title;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Toggle sidebar',
            onPressed: onToggleSidebar,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(width: 14),
          _TopbarIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _ProfileChip(),
        ],
      ),
    );
  }
}

class _TopbarIcon extends StatefulWidget {
  const _TopbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_TopbarIcon> createState() => _TopbarIconState();
}

class _TopbarIconState extends State<_TopbarIcon> {
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
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: IconButton(
          tooltip: widget.tooltip,
          onPressed: widget.onTap,
          icon: Icon(widget.icon, size: 20),
          splashRadius: 20,
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Text(
                'A',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Admin',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 8),
            Icon(Icons.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
