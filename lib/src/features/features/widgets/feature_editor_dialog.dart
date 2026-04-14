import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:flutter/material.dart';

class FeatureEditorDialog extends StatefulWidget {
  const FeatureEditorDialog({
    super.key,
    this.initial,
    required this.groups,
  });

  final FeatureFlag? initial;
  final List<String> groups;

  static Future<FeatureFlag?> show(
    BuildContext context, {
    FeatureFlag? initial,
    required List<String> groups,
  }) {
    return showDialog<FeatureFlag?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FeatureEditorDialog(initial: initial, groups: groups),
    );
  }

  @override
  State<FeatureEditorDialog> createState() => _FeatureEditorDialogState();
}

class _FeatureEditorDialogState extends State<FeatureEditorDialog> {
  late final TextEditingController _key;
  late final TextEditingController _label;
  late final TextEditingController _description;
  late final TextEditingController _icon;
  late final TextEditingController _order;
  late String _group;
  bool _isActive = true;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _key = TextEditingController(text: initial?.key ?? '');
    _label = TextEditingController(text: initial?.label ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _icon = TextEditingController(text: initial?.icon ?? '');
    _order = TextEditingController(text: (initial?.order ?? 0).toString());
    _isActive = initial?.isActive ?? true;

    final groups = widget.groups.where((g) => g != 'All').toList(growable: false);
    _group = initial?.group ?? (groups.isEmpty ? 'Students' : groups.first);
  }

  @override
  void dispose() {
    _key.dispose();
    _label.dispose();
    _description.dispose();
    _icon.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = widget.groups.where((g) => g != 'All').toList(growable: false);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
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
                          _editing ? 'Edit feature' : 'Add feature',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Define system-level feature metadata and access rules.',
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
                title: 'Feature details',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _key,
                            label: 'Feature key',
                            hintText: 'e.g. fee_collect',
                            prefixIcon: Icons.key_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _label,
                            label: 'Label',
                            hintText: 'e.g. Collect Fee',
                            prefixIcon: Icons.text_fields_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            label: 'Group',
                            items: groups,
                            value: _group,
                            itemLabel: (g) => g,
                            prefixIcon: Icons.folder_rounded,
                            onChanged: (v) =>
                                setState(() => _group = v ?? _group),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _icon,
                            label: 'Icon (optional)',
                            hintText: 'e.g. receipt',
                            prefixIcon: Icons.star_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 160,
                          child: AppTextField(
                            controller: _order,
                            label: 'Order',
                            hintText: '0',
                            prefixIcon: Icons.format_list_numbered_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextArea(
                      controller: _description,
                      label: 'Description',
                      hintText: 'Explain what access this feature unlocks.',
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keys must be lowercase with underscores.',
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
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    label: Text(_editing ? 'Save changes' : 'Create feature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final key = _key.text.trim();
    final label = _label.text.trim();
    final description = _description.text.trim();
    final icon = _icon.text.trim();
    final order = int.tryParse(_order.text.trim()) ?? 0;

    if (key.isEmpty || label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key and label are required.')),
      );
      return;
    }

    final keyRegex = RegExp(r'^[a-z0-9_]+$');
    if (!keyRegex.hasMatch(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key must be lowercase and use underscores only.'),
        ),
      );
      return;
    }

    final plan = FeatureFlag(
      id: widget.initial?.id ?? '',
      key: key,
      label: label,
      description: description,
      group: _group,
      isActive: _isActive,
      icon: icon.isEmpty ? null : icon,
      order: order,
      createdAt: widget.initial?.createdAt,
      updatedAt: widget.initial?.updatedAt,
    );

    Navigator.of(context).pop(plan);
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

