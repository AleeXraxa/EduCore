import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
  });

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = collapsed ? 76.0 : 248.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: collapsed
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.stretch,
            children: [
              _BrandRow(collapsed: collapsed, onToggle: onToggle),
              const SizedBox(height: 18),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: true,
                onTap: () {},
              ),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.people_alt_rounded,
                label: 'Students',
                selected: false,
                onTap: () {},
              ),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.payments_rounded,
                label: 'Fees',
                selected: false,
                onTap: () {},
              ),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.fact_check_rounded,
                label: 'Attendance',
                selected: false,
                onTap: () {},
              ),
              const Spacer(),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final logo = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );

    return Row(
      mainAxisAlignment:
          collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        logo,
        if (!collapsed) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'EduCore',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
        ],
        IconButton(
          tooltip: collapsed ? 'Expand' : 'Collapse',
          onPressed: onToggle,
          icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
        ),
      ],
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.collapsed,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool collapsed;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.10)
        : (_hovered ? cs.surfaceContainerHighest : Colors.transparent);

    final fg = widget.selected ? cs.primary : cs.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(widget.icon, color: fg, size: 20),
              if (!widget.collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

