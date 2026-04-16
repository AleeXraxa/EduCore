import 'package:educore/src/features/users/models/app_user.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_kpi_grid.dart';
import 'package:educore/src/core/ui/widgets/app_pagination_bar.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/features/users/users_controller.dart';
import 'package:educore/src/features/users/widgets/create_user_dialog.dart';
import 'package:educore/src/features/users/widgets/user_details_panel.dart';
import 'package:educore/src/features/users/widgets/edit_user_dialog.dart';
import 'package:educore/src/features/users/widgets/users_table.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
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

  Future<void> _handleEdit(BuildContext context, AppUser user) async {
    final updated = await EditUserDialog.show(
      context,
      user: user,
      instituteIds: _controller.institutes,
      instituteLabelForId: _controller.instituteNameForId,
    );
    if (updated == null) return;
    if (!context.mounted) return;

    try {
      AppDialogs.showLoading(context, message: 'Updating account...');
      await _controller.updateUser(
        updated.id,
        name: updated.name,
        phone: updated.phone,
        role: updated.role,
        instituteId: updated.instituteId,
      );
      if (!context.mounted) return;
      AppDialogs.hide(context);
      AppDialogs.showSuccess(
        context,
        title: 'Profile Updated',
        message: 'Account for "${updated.name}" has been updated successfully.',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppDialogs.hide(context);
      AppDialogs.showError(
        context,
        title: 'Update Failed',
        message: e.toString(),
      );
    }
  }

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
                    width: stacked ? double.infinity : 320,
                    controller: _search,
                    onChanged: controller.setQuery,
                    hintText: 'Search users…',
                  ),
                  SizedBox(
                    width: stacked ? double.infinity : 180,
                    height: 48,
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
                    width: stacked ? double.infinity : 200,
                    height: 48,
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
                    width: stacked ? double.infinity : 160,
                    height: 48,
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
                      if (!context.mounted) return;

                      try {
                        AppDialogs.showLoading(
                          context,
                          message: 'Creating user account...',
                        );
                        controller.addUser(created);
                        if (!context.mounted) return;
                        AppDialogs.hide(context);
                        AppDialogs.showSuccess(
                          context,
                          title: 'Account Created',
                          message:
                              'User account for "${created.name}" has been successfully set up.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        AppDialogs.hide(context);
                        AppDialogs.showError(
                          context,
                          title: 'Creation Failed',
                          message: e.toString(),
                        );
                      }
                    },
                    icon: Icons.person_add_rounded,
                    label: 'Add New User',
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sideBySideToolbar)
                    AppAnimatedSlide(
                      delayIndex: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Management',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Manage administrative accounts and staff access across all registered institutes.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: filters(),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    AppAnimatedSlide(
                      delayIndex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage administrative accounts and staff access across all registered institutes.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 24),
                          filters(),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AppAnimatedSlide(
                    delayIndex: 1,
                    child: AppKpiGrid(columns: kpiCols, items: kpis),
                  ),
                  const SizedBox(height: 24),
                  AppAnimatedSlide(
                    delayIndex: 2,
                    child: UsersTable(
                      items: controller.paged,
                      onOpenUser: (user) {
                        UserDetailsPanel.show(
                          context,
                          user: user,
                          onToggleBlocked: () =>
                              controller.toggleBlocked(user.id),
                          onEdit: () => _handleEdit(context, user),
                        );
                      },
                      onAction: (action) async {
                        switch (action.action) {
                          case UserMenuAction.editUser:
                            final user = controller.filtered.firstWhere(
                              (e) => e.id == action.userId,
                            );
                            _handleEdit(context, user);
                            break;
                          case UserMenuAction.viewProfile:
                            final user = controller.filtered.firstWhere(
                              (e) => e.id == action.userId,
                            );
                            UserDetailsPanel.show(
                              context,
                              user: user,
                              onToggleBlocked: () =>
                                  controller.toggleBlocked(action.userId),
                              onEdit: () => _handleEdit(context, user),
                            );
                            break;
                          case UserMenuAction.viewInstitute:
                            break;
                          case UserMenuAction.toggleBlocked:
                            controller.toggleBlocked(action.userId);
                            break;
                          case UserMenuAction.resetPassword:
                            break;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppAnimatedSlide(
                    delayIndex: 3,
                    child: Column(
                      children: [
                        AppPaginationBar(
                          total: controller.totalCount,
                          page: controller.page,
                          pageSize: controller.pageSize,
                          onPrev: controller.prevPage,
                          onNext: controller.nextPage,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: cs.primary, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'SECURITY: All authentication events and access modifications are logged for auditing.',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ],
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
