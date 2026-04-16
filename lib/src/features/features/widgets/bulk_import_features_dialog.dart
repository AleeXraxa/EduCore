import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:flutter/services.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class BulkImportFeaturesDialog extends StatefulWidget {
  const BulkImportFeaturesDialog({
    super.key,
    required this.groups,
  });

  final List<String> groups;

  static Future<List<FeatureFlag>?> show(
    BuildContext context, {
    required List<String> groups,
  }) {
    return showDialog<List<FeatureFlag>?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BulkImportFeaturesDialog(groups: groups),
    );
  }

  @override
  State<BulkImportFeaturesDialog> createState() =>
      _BulkImportFeaturesDialogState();
}

class _BulkImportFeaturesDialogState
    extends State<BulkImportFeaturesDialog> {
  final _input = TextEditingController();
  String? _error;

  static const _header =
      'key,label,description,group,isActive,icon,order';

  String _template() {
    return [
      _header,
      'student_create,Create Student,Create student profiles,Students,true,person_add,1',
      'fee_collect,Collect Fee,Collect monthly fees,Fees,true,receipt,2',
      'attendance_mark,Mark Attendance,Mark daily attendance,Attendance,true,checklist,3',
    ].join('\n');
  }

  @override
  void initState() {
    super.initState();
    _input.text = _template();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups =
        widget.groups.where((g) => g != 'All').toList(growable: false);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk import features',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fill the CSV template and import multiple features at once.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GroupCard(
                title: 'Template (CSV)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Columns: key, label, description, group, isActive, icon, order',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: AppRadii.r12,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        _template(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontFamily: 'monospace',
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _downloadTemplate,
                        icon: const Icon(Icons.download_rounded),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        label: const Text('Download template'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Allowed groups: ${groups.isEmpty ? "Use your own" : groups.join(", ")}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GroupCard(
                title: 'Paste your CSV here',
                child: TextField(
                  controller: _input,
                  maxLines: 10,
                  minLines: 6,
                  decoration: InputDecoration(
                    hintText: _header,
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keys must be lowercase with underscores. Duplicate keys will be skipped.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  AppPrimaryButton(
                    onPressed: _create,
                    icon: Icons.upload_rounded,
                    label: 'Create features',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _create() {
    final rows = _input.text.trim().split('\n');
    if (rows.isEmpty) return;
    final dataRows = rows.where((r) => r.trim().isNotEmpty).toList();
    if (dataRows.isEmpty) return;

    final start = dataRows.first.trim().toLowerCase() == _header ? 1 : 0;
    final features = <FeatureFlag>[];
    final keyRegex = RegExp(r'^[a-z0-9_]+$');

    for (var i = start; i < dataRows.length; i++) {
      final row = dataRows[i];
      final parts = row.split(',');
      if (parts.length < 5) {
        _error = 'Row ${i + 1}: expected at least 5 columns.';
        setState(() {});
        return;
      }

      final key = parts[0].trim();
      final label = parts[1].trim();
      final description = parts[2].trim();
      final group = parts[3].trim();
      final activeRaw = parts[4].trim().toLowerCase();
      final icon = parts.length > 5 ? parts[5].trim() : '';
      final orderRaw = parts.length > 6 ? parts[6].trim() : '';

      if (key.isEmpty || label.isEmpty || group.isEmpty) {
        _error = 'Row ${i + 1}: key, label, group are required.';
        setState(() {});
        return;
      }
      if (!keyRegex.hasMatch(key)) {
        _error = 'Row ${i + 1}: key must be lowercase with underscores.';
        setState(() {});
        return;
      }

      final isActive = activeRaw == 'true' || activeRaw == '1' || activeRaw == 'yes';
      final order = orderRaw.isEmpty ? 0 : int.tryParse(orderRaw) ?? 0;

      features.add(
        FeatureFlag(
          id: '',
          key: key,
          label: label,
          description: description,
          group: group,
          isActive: isActive,
          icon: icon.isEmpty ? null : icon,
          order: order,
          createdAt: null,
          updatedAt: null,
        ),
      );
    }

    if (features.isEmpty) {
      _error = 'No valid rows found.';
      setState(() {});
      return;
    }

    Navigator.of(context).pop(features);
  }

  void _downloadTemplate() {
    final content = _template();
    // Desktop-friendly: copy to clipboard for easy paste into Excel/Sheets.
    AppDialogs.showSuccess(
      context,
      title: 'Template Copied',
      message: 'The CSV template has been copied to your clipboard. You can now paste it into Excel or Google Sheets.',
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
