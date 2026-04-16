import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/institutes/institutes_controller.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:educore/src/features/institutes/widgets/add_institute_dialog.dart';
import 'package:educore/src/features/institutes/widgets/institute_details_panel.dart';
import 'package:educore/src/features/institutes/widgets/edit_institute_dialog.dart';
import 'package:educore/src/features/institutes/widgets/institutes_table.dart';
import 'package:flutter/material.dart';

class InstitutesView extends StatefulWidget {
  const InstitutesView({super.key});

  @override
  State<InstitutesView> createState() => _InstitutesViewState();
}

class _InstitutesViewState extends State<InstitutesView> {
  late final InstitutesController _controller;
  final _search = TextEditingController();
  InstitutesFilter _filter = InstitutesFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = InstitutesController();
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

    return ControllerBuilder<InstitutesController>(
      controller: _controller,
      builder: (context, controller, _) {
        if (!controller.ready) {
          return _NotReadyPanel(
            busy: controller.busy,
            message: controller.errorMessage,
            onRetry: controller.retryInit,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedSlideIn(
                delayIndex: 0,
                child: _Header(
                  search: _search,
                  filter: _filter,
                  onFilterChanged: (value) {
                    setState(() => _filter = value);
                    controller.setFilter(value);
                  },
                  onSearchChanged: controller.setQuery,
                  onAdd: () async {
                    final draft = await AddInstituteDialog.show(context);
                    if (draft == null) return;
                    try {
                      AppDialogs.showLoading(
                        context,
                        message: 'Creating academy...',
                      );
                      await controller.createInstitute(
                        name: draft.name,
                        ownerName: draft.ownerName,
                        email: draft.email,
                        phone: draft.phone,
                        address: draft.address,
                        adminEmail: draft.adminEmail,
                        adminPassword: draft.adminPassword,
                      );
                      if (!context.mounted) return;
                      AppDialogs.hide(context);
                      AppDialogs.showSuccess(
                        context,
                        title: 'Academy Created',
                        message:
                            '${draft.name} has been successfully registered on the platform.',
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
                ),
              ),
              const SizedBox(height: 32),
              _AnimatedSlideIn(
                delayIndex: 1,
                child: InstitutesTable(
                  items: controller.paged,
                  planLabel: controller.planLabel,
                  onAction: (action) async {
                    switch (action.action) {
                      case InstituteMenuAction.block:
                      case InstituteMenuAction.unblock:
                        controller.toggleBlocked(action.instituteId);
                        break;
                      case InstituteMenuAction.view:
                        final institute = controller.paged.firstWhere(
                          (e) => e.id == action.instituteId,
                        );
                        InstituteDetailsPanel.show(
                          context,
                          institute: institute,
                          planLabel: controller.planLabel(institute.planId),
                          onToggleBlocked: () =>
                              controller.toggleBlocked(action.instituteId),
                        );
                        break;
                      case InstituteMenuAction.edit:
                        final institute = controller.paged.firstWhere(
                          (e) => e.id == action.instituteId,
                        );
                        final endDate = await controller.getSubscriptionEndDate(
                          institute.id,
                        );
                        if (!context.mounted) return;
                        final draft = await EditInstituteDialog.show(
                          context,
                          institute: institute,
                          plans: controller.plans,
                          initialEndDate: endDate,
                        );
                        if (draft == null) return;
                        try {
                          AppDialogs.showLoading(
                            context,
                            message: 'Updating institute...',
                          );
                          await controller.updateInstitute(
                            academyId: institute.id,
                            name: draft.name,
                            ownerName: draft.ownerName,
                            email: draft.email,
                            phone: draft.phone,
                            address: draft.address,
                            planId: draft.planId,
                            status: draft.status,
                            endDate: draft.endDate,
                          );
                          if (!context.mounted) return;
                          AppDialogs.hide(context);
                          AppDialogs.showSuccess(
                            context,
                            title: 'Profile Updated',
                            message:
                                'Academy profile for "${draft.name}" has been saved successfully.',
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
                        break;
                      case InstituteMenuAction.delete:
                        break;
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              _PaginationBar(
                total: controller.totalCount,
                page: controller.page,
                pageSize: controller.pageSize,
                onPrev: controller.prevPage,
                onNext: controller.nextPage,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Search for institutes by name, email, or owner.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.search,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final TextEditingController search;
  final InstitutesFilter filter;
  final ValueChanged<InstitutesFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Institutes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage all registered institutes on EduCore.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        AppSearchField(
          width: 360,
          controller: search,
          onChanged: onSearchChanged,
          hintText: 'Search institute / owner / email',
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          height: toolbarHeight,
          child: AppDropdown<InstitutesFilter>(
            label: 'Status',
            compact: true,
            showLabel: false,
            items: const [
              InstitutesFilter.all,
              InstitutesFilter.pending,
              InstitutesFilter.active,
              InstitutesFilter.blocked,
            ],
            value: filter,
            hintText: 'Status',
            prefixIcon: Icons.filter_alt_rounded,
            itemLabel: (f) => switch (f) {
              InstitutesFilter.all => 'All',
              InstitutesFilter.pending => 'Pending',
              InstitutesFilter.active => 'Active',
              InstitutesFilter.blocked => 'Blocked',
            },
            onChanged: (value) {
              if (value == null) return;
              onFilterChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: HoverScale(
            child: SizedBox(
              height: toolbarHeight,
              child: AppPrimaryButton(
                label: '+ Add Institute',
                icon: Icons.add_rounded,
                onPressed: onAdd,
              ),
            ),
          ),
        ),
      ],
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
          onTap: onPrev,
        ),
        const SizedBox(width: 8),
        _PagerIcon(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next',
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
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Icon(widget.icon, color: cs.onSurfaceVariant),
          ),
        ),
      ),
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
                    busy ? 'Initializing Firebase...' : 'Firestore not ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message?.trim().isNotEmpty == true
                        ? message!.trim()
                        : 'Institutes require Firebase Firestore. Initialize Firebase to enable this module.',
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

class _AnimatedSlideIn extends StatelessWidget {
  const _AnimatedSlideIn({required this.child, required this.delayIndex});
  final Widget child;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delayIndex * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
