import 'dart:convert';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AuditLogDetailsDialog extends StatelessWidget {
  const AuditLogDetailsDialog({super.key, required this.log});

  final AuditLog log;

  static Future<void> show(BuildContext context, AuditLog log) {
    return showDialog(
      context: context,
      builder: (_) => AuditLogDetailsDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('MMMM dd, yyyy • HH:mm:ss').format(log.createdAt);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 850,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadii.r24,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Gradient Backdrop
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.surfaceContainerLowest,
                    cs.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                   _SeverityBadge(log.severity, large: true),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.action.replaceAll('_', ' ').toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: cs.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const _SectionTitle(title: 'Activity Information', icon: Icons.info_outline_rounded),
                     const SizedBox(height: 16),
                     _InfoGrid(log: log),
                     const SizedBox(height: 40),
                     
                     if (log.before != null || log.after != null) ...[
                       const _SectionTitle(title: 'State Comparison', icon: Icons.compare_arrows_rounded),
                       const SizedBox(height: 20),
                       _StateComparisonLayout(
                         before: log.before,
                         after: log.after,
                       ),
                       const SizedBox(height: 24),
                     ],
                   ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOG ID: ${log.id}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  AppPrimaryButton(
                    label: 'Close View',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.log});
  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: [
        _InfoItem(label: 'Module', value: log.module.toUpperCase(), icon: Icons.extension_rounded),
        _InfoItem(label: 'Performing User', value: log.userName, icon: Icons.person_rounded, subValue: log.actorId),
        _InfoItem(label: 'User Role', value: log.role.toUpperCase(), icon: Icons.admin_panel_settings_rounded),
        _InfoItem(label: 'Institute ID', value: log.academyId, icon: Icons.business_rounded),
        _InfoItem(label: 'Source', value: log.source.name.toUpperCase(), icon: Icons.devices_rounded),
        if (log.targetId != null)
           _InfoItem(label: 'Target Resource', value: log.targetId!, icon: Icons.data_object_rounded),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value, required this.icon, this.subValue});
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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

class _StateComparisonLayout extends StatelessWidget {
  const _StateComparisonLayout({this.before, this.after});
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (before != null) ...[
          Expanded(child: _JsonViewer(title: 'Previous State', data: before!, color: Colors.blueGrey)),
          if (after != null) const SizedBox(width: 24),
        ],
        if (after != null)
          Expanded(child: _JsonViewer(title: 'Updated State', data: after!, color: Colors.indigo)),
      ],
    );
  }
}

class _JsonViewer extends StatelessWidget {
  const _JsonViewer({required this.title, required this.data, required this.color});
  final String title;
  final Map<String, dynamic> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: SelectableText(
            jsonStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge(this.severity, {this.large = false});
  final AuditSeverity severity;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AuditSeverity.critical => Colors.red,
      AuditSeverity.warning => Colors.orange,
      AuditSeverity.info => Colors.blueGrey,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            severity.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: large ? 12 : 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
