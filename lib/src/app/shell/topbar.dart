import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';

class Topbar extends StatelessWidget {
  const Topbar({super.key, required this.title, required this.onToggleSidebar});

  final String title;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Toggle sidebar',
            onPressed: onToggleSidebar,
            icon: Icon(Icons.menu_rounded, color: cs.onSurfaceVariant),
            style: IconButton.styleFrom(
              hoverColor: cs.onSurface.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _SearchField(),
          const SizedBox(width: 20),
          _TopbarIcon(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            hasBadge: true,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _TopbarIcon(
            icon: Icons.help_outline_rounded,
            tooltip: 'Help Center',
            onTap: () {},
          ),
          const SizedBox(width: 16),
          const _SessionChip(),
        ],
      ),
    );
  }
}

/// Compact session chip shown in the topbar — displays the signed-in admin's
/// avatar initials and their name/role so it's always visible at a glance.
class _SessionChip extends StatelessWidget {
  const _SessionChip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = AppServices.instance.authService?.session;
    final name = session?.user.name.isNotEmpty == true
        ? session!.user.name
        : (session?.user.role.name.replaceAll('_', ' ').toUpperCase() ?? 'Super Admin');
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: cs.onSurface,
                ),
              ),
              Text(
                (session?.user.role.name.replaceAll('_', ' ').toUpperCase() ?? 'SUPER ADMIN'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
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

class _SearchField extends StatefulWidget {
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isFocused ? 380 : 320,
      child: TextField(
        focusNode: _focus,
        decoration: InputDecoration(
          hintText: 'Search or jump to...',
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused ? cs.primary : cs.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: !_isFocused
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: _isFocused
              ? cs.surface
              : cs.surfaceContainerLowest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _TopbarIcon extends StatefulWidget {
  const _TopbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  State<_TopbarIcon> createState() => _TopbarIconState();
}

class _TopbarIconState extends State<_TopbarIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _hovered
                      ? cs.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hovered
                        ? cs.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: _hovered ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              if (widget.hasBadge)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
