import 'dart:async';

import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/constants/prefs_keys.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
    this.items = const [],
    this.selectedId,
    this.onSelect,
    this.bottomItems = const [],
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final List<SidebarItemData> items;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final List<SidebarItemData> bottomItems;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 76.0 : 248.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
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
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: collapsed
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        _NavItem(
                          collapsed: collapsed,
                          icon: item.icon,
                          label: item.label,
                          selected: selectedId == item.id,
                          onTap: () => onSelect?.call(item.id),
                        ),
                    ],
                  ),
                ),
              ),
              if (bottomItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Divider(height: 1, color: AppColors.border),
                ),
              for (final item in bottomItems)
                _NavItem(
                  collapsed: collapsed,
                  icon: item.icon,
                  label: item.label,
                  selected: selectedId == item.id,
                  onTap: () => onSelect?.call(item.id),
                ),
              _NavItem(
                collapsed: collapsed,
                icon: Icons.logout_rounded,
                label: 'Log out',
                selected: false,
                danger: true,
                onTap: () => unawaited(_onLogout(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign out'),
          content: Text(
            'You will be returned to the login screen.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: cs.primary),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final authService = AppServices.instance.authService;
    if (authService == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth is not available yet.')),
      );
      return;
    }

    try {
      await authService.signOut();
      await AppServices.instance.prefs.setBool(PrefsKeys.rememberMe, false);
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        color: cs.surface,
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/images/logo_v4.png',
          fit: BoxFit.contain,
        ),
      ),
    );

    if (collapsed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          const SizedBox(height: 8),
          IconButton(
            tooltip: 'Expand',
            onPressed: onToggle,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          ),
        ],
      );
    }

    return Row(
      children: [
        logo,
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
        IconButton(
          tooltip: 'Collapse',
          onPressed: onToggle,
          icon: const Icon(Icons.chevron_left),
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
    this.danger = false,
  });

  final bool collapsed;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;

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

    final fg = widget.danger
        ? (widget.selected ? const Color(0xFFDC2626) : const Color(0xFFB91C1C))
        : (widget.selected ? cs.primary : cs.onSurfaceVariant);

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
          hoverColor: (widget.danger ? fg : cs.primary).withValues(alpha: 0.06),
          splashColor:
              (widget.danger ? fg : cs.primary).withValues(alpha: 0.10),
          onHover: (value) => setState(() => _hovered = value),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (widget.selected && !widget.collapsed) ...[
                  Container(
                    width: 4,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.danger ? fg : cs.primary,
                          widget.danger ? fg : cs.secondary,
                        ],
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }
}
