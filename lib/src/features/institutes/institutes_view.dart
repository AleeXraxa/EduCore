import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/institutes/institutes_controller.dart';
import 'package:educore/src/features/institutes/widgets/add_institute_dialog.dart';
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                search: _search,
                filter: _filter,
                onFilterChanged: (value) {
                  setState(() => _filter = value);
                  controller.setFilter(value);
                },
                onSearchChanged: controller.setQuery,
                onAdd: () async {
                  final created = await AddInstituteDialog.show(context);
                  if (created == null) return;
                  controller.addInstitute(created);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Institute created: ${created.name}'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              InstitutesTable(
                items: controller.paged,
                onAction: (action) {
                  switch (action.action) {
                    case InstituteMenuAction.block:
                    case InstituteMenuAction.unblock:
                      controller.toggleBlocked(action.instituteId);
                      break;
                    case InstituteMenuAction.view:
                    case InstituteMenuAction.edit:
                    case InstituteMenuAction.delete:
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Action: ${action.action.name}')),
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
                'Tip: Use search + filters to quickly find an institute.',
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 360,
          height: toolbarHeight,
          child: TextField(
            controller: search,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search institute / owner / email',
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
              InstitutesFilter.active,
              InstitutesFilter.expired,
              InstitutesFilter.blocked,
            ],
            value: filter,
            hintText: 'Status',
            prefixIcon: Icons.filter_alt_rounded,
            itemLabel: (f) => switch (f) {
              InstitutesFilter.all => 'All',
              InstitutesFilter.active => 'Active',
              InstitutesFilter.expired => 'Expired',
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
