import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: _editing ? 'Edit Feature' : 'Add New Feature',
              subtitle: 'Define a feature that can be enabled or disabled per plan.',
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    _AnimatedSlideIn(
                      delayIndex: 0,
                      child: _GroupCard(
                        title: 'FEATURE DETAILS',
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _key,
                              label: 'Feature Key',
                              hintText: 'e.g. library_module',
                              prefixIcon: Icons.key_rounded,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _label,
                              label: 'Display Name',
                              hintText: 'e.g. Library Management',
                              prefixIcon: Icons.text_fields_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 1,
                      child: _GroupCard(
                        title: 'CATEGORY & ORDERING',
                        child: Column(
                          children: [
                            AppDropdown<String>(
                              label: 'Feature Group',
                              items: groups,
                              value: _group,
                              itemLabel: (g) => g,
                              prefixIcon: Icons.folder_rounded,
                              onChanged: (v) =>
                                  setState(() => _group = v ?? _group),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    controller: _icon,
                                    label: 'Icon Name',
                                    hintText: 'e.g. book',
                                    prefixIcon: Icons.star_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _order,
                                    label: 'Weight',
                                    hintText: '0',
                                    prefixIcon: Icons.format_list_numbered_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 2,
                      child: _GroupCard(
                        title: 'DESCRIPTION',
                        child: Column(
                          children: [
                            AppTextArea(
                              controller: _description,
                              label: 'Description',
                              hintText: 'What does this feature enable for the institute?',
                              minLines: 2,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            _StatusToggle(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.05),
                          borderRadius: AppRadii.r16,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Feature keys must use snake_case (e.g. fee_management) and cannot be changed once assigned to a plan.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              editing: _editing,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _submit,
            ),
          ],
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
      AppDialogs.showError(
        context,
        title: 'Validation Error',
        message: 'Feature key and display label are required.',
      );
      return;
    }

    final keyRegex = RegExp(r'^[a-z0-9_]+$');
    if (!keyRegex.hasMatch(key)) {
      AppDialogs.showError(
        context,
        title: 'Invalid Key Format',
        message: 'Keys must lowercase alphanumeric characters and underscores only.',
      );
      return;
    }

    final feature = FeatureFlag(
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

    Navigator.of(context).pop(feature);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.editing,
    required this.onCancel,
    required this.onSave,
  });
  final bool editing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Text(
              'Discard',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppPrimaryButton(
            onPressed: onSave,
            label: editing ? 'Update Feature' : 'Add Feature',
            icon: editing ? Icons.update_rounded : Icons.add_rounded,
          ),
        ],
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

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r12,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            color: value ? Colors.green : cs.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ? 'ACTIVE / VISIBLE' : 'DEACTIVATED / HIDDEN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
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
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

