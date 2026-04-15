import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/users/users_controller.dart';
import 'package:educore/src/features/users/widgets/create_user_dialog.dart';
import 'package:educore/src/features/users/widgets/user_details_panel.dart';
import 'package:educore/src/features/users/widgets/users_table.dart';
import 'package:flutter/material.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  late final UsersController _controller;
  final _search = TextEditingController();
  UsersRoleFilter _role = UsersRoleFilter.all;
  UsersStatusFilter _status = UsersStatusFilter.all;
  String _instituteId = 'all';

  @override
  void initState() {
    super.initState();
    _controller = UsersController();
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;

    return ControllerBuilder<UsersController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final stacked = size == ScreenSize.compact;
            final sideBySideToolbar = !stacked && constraints.maxWidth >= 1520;
            final kpiCols = switch (size) {
              ScreenSize.compact => 1,
              ScreenSize.medium => 2,
              ScreenSize.expanded => 4,
            };

            final kpis = [
              KpiCardData(
                label: 'Total Users',
                value: _fmtInt(controller.allCount),
                icon: Icons.people_alt_rounded,
                gradient: const [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
              KpiCardData(
                label: 'Active Users',
                value: _fmtInt(controller.activeCount),
                icon: Icons.verified_user_rounded,
                gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
              ),
              KpiCardData(
                label: 'Institute Admins',
                value: _fmtInt(controller.instituteAdminsCount),
                icon: Icons.admin_panel_settings_rounded,
                gradient: const [Color(0xFF7C3AED), Color(0xFF6366F1)],
              ),
              KpiCardData(
                label: 'Teachers / Staff',
                value: _fmtInt(controller.staffTeachersCount),
                icon: Icons.badge_rounded,
                gradient: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
              ),
            ];

            Widget filters() {
              final instituteItems = controller.institutes;
              if (_instituteId != 'all' &&
                  !instituteItems.contains(_instituteId)) {
                _instituteId = 'all';
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  AppSearchField(
                    width: stacked ? double.infinity : 340,
                    controller: _search,
                    onChanged: controller.setQuery,
                    hintText: 'Search name / email / phone',
                  ),
                  SizedBox(
                    width: stacked ? double.infinity : 190,
                    height: toolbarHeight,
                    child: AppDropdown<UsersRoleFilter>(
                      label: 'Role',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.badge_rounded,
                      items: const [
                        UsersRoleFilter.all,
                        UsersRoleFilter.superAdmin,
                        UsersRoleFilter.instituteAdmin,
                        UsersRoleFilter.staff,
                        UsersRoleFilter.teacher,
                      ],
                      value: _role,
                      hintText: 'Role',
                      itemLabel: (r) => switch (r) {
                        UsersRoleFilter.all => 'All roles',
                        UsersRoleFilter.superAdmin => 'Super Admin',
                        UsersRoleFilter.instituteAdmin => 'Institute Admin',
                        UsersRoleFilter.staff => 'Staff',
                        UsersRoleFilter.teacher => 'Teacher',
                      },
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _role = v);
                        controller.setRole(v);
                      },
                    ),
                  ),
                  SizedBox(
                    width: stacked ? double.infinity : 210,
                    height: toolbarHeight,
                    child: AppDropdown<String>(
                      label: 'Institute',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.apartment_rounded,
                      items: instituteItems,
                      value: _instituteId,
                      hintText: 'Institute',
                      itemLabel: controller.instituteNameForId,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _instituteId = v);
                        controller.setInstitute(v);
                      },
                    ),
                  ),
                  SizedBox(
                    width: stacked ? double.infinity : 170,
                    height: toolbarHeight,
                    child: AppDropdown<UsersStatusFilter>(
                      label: 'Status',
                      showLabel: false,
                      compact: true,
                      prefixIcon: Icons.filter_alt_rounded,
                      items: const [
                        UsersStatusFilter.all,
                        UsersStatusFilter.active,
                        UsersStatusFilter.blocked,
                      ],
                      value: _status,
                      hintText: 'Status',
                      itemLabel: (s) => switch (s) {
                        UsersStatusFilter.all => 'All',
                        UsersStatusFilter.active => 'Active',
                        UsersStatusFilter.blocked => 'Blocked',
                      },
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _status = v);
                        controller.setStatus(v);
                      },
                    ),
                  ),
                  AppPrimaryButton(
                    width: stacked ? double.infinity : 180,
                    onPressed: () async {
                      final created = await CreateUserDialog.show(
                        context,
                        instituteIds: controller.institutes,
                        instituteLabelForId: controller.instituteNameForId,
                      );
                      if (created == null) return;
                      controller.addUser(created);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User created: ${created.name}'),
                        ),
                      );
                    },
                    icon: Icons.add_rounded,
                    label: 'Create user',
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sideBySideToolbar)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Users',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Global directory for system-wide monitoring and access control.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: filters(),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      'Users',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Global directory for system-wide monitoring and access control.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    filters(),
                  ],
                  const SizedBox(height: 16),
                  _KpiGrid(columns: kpiCols, items: kpis),
                  const SizedBox(height: 20),
                  UsersTable(
                    items: controller.paged,
                    onOpenUser: (user) => UserDetailsPanel.show(
                      context,
                      user: user,
                      onToggleBlocked: () => controller.toggleBlocked(user.id),
                    ),
                    onAction: (action) {
                      switch (action.action) {
                        case UserMenuAction.viewProfile:
                          final user = controller.filtered.firstWhere(
                            (e) => e.id == action.userId,
                          );
                          UserDetailsPanel.show(
                            context,
                            user: user,
                            onToggleBlocked: () =>
                                controller.toggleBlocked(action.userId),
                          );
                          break;
                        case UserMenuAction.viewInstitute:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Institute details page (next step).',
                              ),
                            ),
                          );
                          break;
                        case UserMenuAction.toggleBlocked:
                          controller.toggleBlocked(action.userId);
                          break;
                        case UserMenuAction.resetPassword:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reset password is coming soon.'),
                            ),
                          );
                          break;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _PaginationBar(
                    total: controller.totalCount,
                    page: controller.page,
                    pageSize: controller.pageSize,
                    onPrev: controller.prevPage,
                    onNext: controller.nextPage,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: Use role + institute filters to quickly audit access.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.columns, required this.items});

  final int columns;
  final List<KpiCardData> items;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = gap * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalGap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: KpiCard(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _NotReadyPanel extends StatelessWidget {
  const _NotReadyPanel({
    this.busy = false,
    this.message,
    required this.onRetry,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
          boxShadow: AppShadows.soft(Colors.black),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.cloud_off_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    busy ? 'Initializing Firebase…' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Users require Firebase Firestore. Initialize Firebase to enable this module.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: busy ? null : () async => onRetry(),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final int total;
  final int page;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final start = total == 0 ? 0 : (page * pageSize) + 1;
    final end = (page * pageSize + pageSize).clamp(0, total);

    return Row(
      children: [
        Text(
          '$start–$end of $total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _PagerIcon(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous',
          enabled: page > 0,
          onTap: onPrev,
        ),
        const SizedBox(width: 8),
        _PagerIcon(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next',
          enabled: (page + 1) * pageSize < total,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PagerIcon extends StatefulWidget {
  const _PagerIcon({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PagerIcon> createState() => _PagerIconState();
}

class _PagerIconState extends State<_PagerIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered ? cs.surfaceContainerHighest : cs.surface;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: IconButton(
            tooltip: widget.tooltip,
            onPressed: widget.enabled ? widget.onTap : null,
            icon: Icon(widget.icon),
            splashRadius: 18,
            iconSize: 20,
          ),
        ),
      ),
    );
  }
}

String _fmtInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = s.length - i;
    buf.write(s[i]);
    if (idx > 1 && idx % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
