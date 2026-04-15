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
    final cs = Theme.of(context).colorScheme;
    final width = collapsed ? 92.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _BrandRow(collapsed: collapsed, onToggle: onToggle),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (bottomItems.isNotEmpty) ...[
                    for (final item in bottomItems)
                      _NavItem(
                        collapsed: collapsed,
                        icon: item.icon,
                        label: item.label,
                        selected: selectedId == item.id,
                        onTap: () => onSelect?.call(item.id),
                      ),
                    const SizedBox(height: 12),
                  ],
                  _NavItem(
                    collapsed: collapsed,
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    selected: false,
                    danger: true,
                    onTap: () => unawaited(_onLogout(context)),
                  ),
                ],
              ),
            ),
          ],
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
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Logout',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to exit the current session?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final authService = AppServices.instance.authService;
    if (authService == null) return;

    try {
      await AppServices.instance.prefs.setBool(PrefsKeys.signedIn, false);
      await authService.signOut();
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {}
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settingsService = AppServices.instance.settingsService;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 8),
      child: StreamBuilder(
        stream: settingsService?.watchGlobalSettings(),
        builder: (context, snapshot) {
          final settings = snapshot.data;
          final appName = settings?.appName ?? 'EduCore';
          final logoUrl = settings?.appLogoUrl;
          final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

          return Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                padding: EdgeInsets.all(hasLogo ? 0 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasLogo
                      ? Image.network(logoUrl, fit: BoxFit.cover)
                      : Image.asset(
                          'assets/images/logo_v4.png',
                          color: Colors.white,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              letterSpacing: -0.8,
                              fontSize: 18,
                            ),
                      ),
                      Text(
                        'Management',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _ToggleBtn(collapsed: collapsed, onToggle: onToggle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.collapsed, required this.onToggle});
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            collapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
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

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final primaryColor = widget.danger ? const Color(0xFFDC2626) : cs.primary;
    final indicatorColor = widget.danger ? const Color(0xFFDC2626) : cs.primary;

    final bg = widget.selected
        ? primaryColor.withValues(alpha: 0.08)
        : (_hovered
              ? cs.onSurface.withValues(alpha: 0.04)
              : Colors.transparent);

    final fg = widget.selected
        ? primaryColor
        : (widget.danger ? const Color(0xFFB91C1C) : cs.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hovered = v),
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.selected
                    ? primaryColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: widget.selected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(widget.icon, color: fg, size: 22),
                  ],
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: fg,
                        fontWeight: widget.selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        letterSpacing: widget.selected ? -0.2 : 0,
                      ),
                      child: Text(widget.label),
                    ),
                  ),
                  if (widget.selected)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: indicatorColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
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
