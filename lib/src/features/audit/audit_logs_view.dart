import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/audit/audit_logs_controller.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/audit/widgets/audit_logs_table.dart';
import 'package:flutter/material.dart';

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
    return ControllerBuilder(
      controller: _controller,
      builder: (context, controller, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(controller: controller),
                const SizedBox(height: 32),
                _Filters(controller: controller),
                const SizedBox(height: 24),
                if (controller.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(child: AuditLogsTable(logs: controller.logs)),
              ],
            ),
          ),
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
              'Complete traceability of critical actions across the EduCore ecosystem.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: controller.refreshLogs,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
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
              items: [null, ...AuditSeverity.values],
              value: controller.selectedSeverity,
              itemLabel: (s) => s == null ? 'All Severities' : s.name.toUpperCase(),
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
                  'INSTITUTE ID',
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
                    onChanged: controller.setSearchAcademy,
                    decoration: InputDecoration(
                      hintText: 'Search by Academy ID...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.r12,
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
