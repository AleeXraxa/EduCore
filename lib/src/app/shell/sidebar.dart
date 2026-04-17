import 'dart:async';

import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/app/shell/sidebar_item.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
    this.sections = const [],
    this.selectedId,
    this.onSelect,
    this.bottomItems = const [],
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final List<SidebarSectionData> sections;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final List<SidebarItemData> bottomItems;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = collapsed ? 80.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
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
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: AppServices.instance.featureAccessService?.accessStream,
          initialData: AppServices.instance.featureAccessService
              ?.getAllowedFeatures()
              .toSet(),
          builder: (context, snapshot) {
            return Column(
              children: [
                _BrandRow(collapsed: collapsed, onToggle: onToggle),
                const SizedBox(height: 32),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < sections.length; i++) ...[
                            if (sections[i].items.any(
                              (item) =>
                                  item.requiredFeature == null ||
                                  (AppServices.instance.featureAccessService
                                          ?.canAccess(item.requiredFeature!) ??
                                      true),
                            )) ...[
                              _SectionHeader(
                                title: sections[i].title,
                                collapsed: collapsed,
                              ),
                              const SizedBox(height: 8),
                              for (final item in sections[i].items)
                                if (item.requiredFeature == null ||
                                    (AppServices.instance.featureAccessService
                                            ?.canAccess(
                                              item.requiredFeature!,
                                            ) ??
                                        true))
                                  _NavItem(
                                    collapsed: collapsed,
                                    icon: item.icon,
                                    label: item.label,
                                    selected: selectedId == item.id,
                                    onTap: () => onSelect?.call(item.id),
                                  ),
                              if (i < sections.length - 1)
                                const SizedBox(height: 24)
                              else
                                const SizedBox(height: 16),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    collapsed ? 8 : 16,
                    8,
                    collapsed ? 8 : 16,
                    24,
                  ),
                  child: Column(
                    children: [
                      if (bottomItems.isNotEmpty) ...[
                        for (final item in bottomItems)
                          if (item.requiredFeature == null ||
                              (AppServices.instance.featureAccessService
                                      ?.canAccess(item.requiredFeature!) ??
                                  true))
                            _NavItem(
                              collapsed: collapsed,
                              icon: item.icon,
                              label: item.label,
                              selected: selectedId == item.id,
                              onTap: () => onSelect?.call(item.id),
                            ),
                        const SizedBox(height: 12),
                      ],
                      _AccountSection(collapsed: collapsed),
                    ],
                  ),
                ),
              ],
            );
          },
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
    final settingsService = AppServices.instance.settingsService;

    return Container(
      padding: collapsed
          ? const EdgeInsets.symmetric(vertical: 20)
          : const EdgeInsets.fromLTRB(20, 20, 16, 8),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasLogo
                      ? Image.network(logoUrl, fit: BoxFit.cover)
                      : const Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 16),
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
                              letterSpacing: -1.0,
                              fontSize: 16,
                            ),
                      ),
                      Text(
                        (AppServices.instance.authService?.session?.user.role.name.replaceAll('_', ' ').toUpperCase() ?? 'PLATFORM ADMIN'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 9,
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

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = AppServices.instance.authService?.session;
    final displayName = session?.user.name.isNotEmpty == true
        ? session!.user.name
        : (session?.user.role.name.replaceAll('_', ' ').toUpperCase() ?? 'Admin');
    final displayEmail = session?.user.email.isNotEmpty == true
        ? session!.user.email
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: collapsed
            ? Colors.transparent
            : cs.surfaceContainerLow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: collapsed
              ? Colors.transparent
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                _Avatar(collapsed: collapsed, name: displayName),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                        ),
                        if (displayEmail.isNotEmpty)
                          Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
          ],
          _NavItem(
            collapsed: collapsed,
            icon: Icons.logout_rounded,
            label: 'Logout',
            selected: false,
            danger: true,
            onTap: () => unawaited(_onLogout(context)),
          ),
        ],
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
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Logout'),
            ],
          ),
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Stay Logged In',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Logout Now',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await AppServices.instance.authService?.signOut();
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.collapsed, required this.name});
  final bool collapsed;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = collapsed ? 36.0 : 40.0;
    final initials = _initials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: collapsed ? 14 : 16,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'SA';
    final first = parts.first.isEmpty ? '' : parts.first[0];
    final last = parts.length >= 2 ? parts.last[0] : '';
    return (first + last).toUpperCase();
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
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
    final bg = widget.selected
        ? primaryColor.withValues(alpha: 0.08)
        : (_hovered
              ? cs.onSurface.withValues(alpha: 0.04)
              : Colors.transparent);

    final fg = widget.selected
        ? primaryColor
        : (widget.danger ? const Color(0xFFB91C1C) : cs.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 4 : 12,
              vertical: 10,
            ),
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
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(widget.icon, color: fg, size: 20),
                  ],
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: fg,
                        fontWeight: widget.selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        letterSpacing: widget.selected ? -0.2 : 0,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.collapsed});
  final String title;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Divider(height: 1),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 10,
        ),
      ),
    );
  }
}
