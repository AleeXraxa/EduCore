import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/audit/audit_logs_controller.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/audit/widgets/audit_logs_table.dart';
import 'package:educore/src/core/ui/widgets/app_loading_overlay.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final _controller = AuditLogsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder<AuditLogsController>(
      controller: _controller,
      builder: (context, controller, child) {
        final featureSvc = AppServices.instance.featureAccessService;
        if (featureSvc == null || !featureSvc.canAccess('audit_view')) {
          return const AccessDeniedView(featureName: 'System Audit Logs');
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final screen = screenSizeForWidth(constraints.maxWidth);
            final horizontalPadding = screen == ScreenSize.compact ? 16.0 : 32.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAnimatedSlide(
                    child: _Header(controller: controller),
                  ),
                  const SizedBox(height: 32),
                  AppAnimatedSlide(
                    delayIndex: 1,
                    child: _Filters(controller: controller),
                  ),
                  const SizedBox(height: 24),
                  AppLoadingOverlay(
                    isLoading: controller.busy && controller.logs.isEmpty,
                    message: 'Fetching Logs',
                    child: Column(
                      children: [
                        AppAnimatedSlide(
                          delayIndex: 2,
                          child: AuditLogsTable(logs: controller.logs),
                        ),
                        if (controller.hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: FilledButton.icon(
                              onPressed: controller.isLoadingMore ? null : controller.loadMore,
                              icon: controller.isLoadingMore 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.expand_more_rounded),
                              label: const Text('Load More Audit History'),
                            ),
                          ),
                        const SizedBox(height: 32),
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

class _Header extends StatelessWidget {
  final AuditLogsController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Logs',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete traceability of critical actions across the system.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh Logs',
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  final AuditLogsController controller;
  const _Filters({required this.controller});

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: controller.startDate != null && controller.endDate != null
          ? DateTimeRange(start: controller.startDate!, end: controller.endDate!)
          : null,
    );
    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppDropdown<String?>(
                  label: 'Module',
                  items: [null, ...controller.availableModules],
                  value: controller.selectedModule,
                  itemLabel: (m) => m == null ? 'All Modules' : m.toUpperCase(),
                  onChanged: (val) => controller.setModule(val),
                  compact: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppDropdown<AuditSeverity?>(
                  label: 'Severity',
                  items: const [null, ...AuditSeverity.values],
                  value: controller.selectedSeverity,
                  itemLabel: (s) =>
                      s == null ? 'All Severities' : s.name.toUpperCase(),
                  onChanged: (val) => controller.setSeverity(val),
                  compact: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE RANGE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
                            const SizedBox(width: 12),
                            Text(
                              controller.startDate == null 
                                ? 'Pick Date Range'
                                : '${DateFormat('MM/dd').format(controller.startDate!)} - ${DateFormat('MM/dd').format(controller.endDate!)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (controller.startDate != null) ...[
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => controller.setDateRange(null, null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  label: 'ACADEMY ID',
                  hint: 'Search by Academy...',
                  onChanged: controller.setSearchAcademy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SearchField(
                  label: 'ACTOR (USER ID)',
                  hint: 'Search by User ID...',
                  onChanged: controller.setActor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _SearchField({
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextField(
            onChanged: (val) => onChanged(val.isEmpty ? null : val),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
