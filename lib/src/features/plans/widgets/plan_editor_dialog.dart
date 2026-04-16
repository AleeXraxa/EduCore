import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class PlanEditorDialog extends StatefulWidget {
  const PlanEditorDialog({
    super.key,
    this.initial,
    required this.availableFeatures,
  });

  final Plan? initial;
  final List<FeatureFlag> availableFeatures;

  static Future<Plan?> show(
    BuildContext context, {
    Plan? initial,
    required List<FeatureFlag> availableFeatures,
  }) {
    return showDialog<Plan?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PlanEditorDialog(
        initial: initial,
        availableFeatures: availableFeatures,
      ),
    );
  }

  @override
  State<PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<PlanEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _duration;

  late Set<String> _features;
  late Map<String, num> _limits;

  final _newLimitKey = TextEditingController();
  final _newLimitValue = TextEditingController();

  bool _isActive = true;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _price = TextEditingController(text: (initial?.price ?? 0).toString());
    _description = TextEditingController(text: initial?.description ?? '');
    _duration = TextEditingController(text: (initial?.durationDays ?? 30).toString());
    _isActive = initial?.isActive ?? true;

    _features = {...(initial?.features ?? const [])};

    _limits = Map<String, num>.from(initial?.limits ?? const {});
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _newLimitKey.dispose();
    _newLimitValue.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _addLimit() {
    final rawKey = _newLimitKey.text.trim();
    if (rawKey.isEmpty) return;
    final rawValue = _newLimitValue.text.trim();
    final parsed = num.tryParse(rawValue);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limit value must be a number.')),
      );
      return;
    }
    final key = rawKey.replaceAll(' ', '_');
    setState(() {
      _limits[key] = parsed;
      _newLimitKey.clear();
      _newLimitValue.clear();
    });
  }

  void _submit() {
    final name = _name.text.trim();
    final price = num.tryParse(_price.text.trim()) ?? 0;
    final description = _description.text.trim();
    final duration = int.tryParse(_duration.text.trim()) ?? 30;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan name is required.')),
      );
      return;
    }

    final cleanedFeatures =
        _features.where((k) => k.trim().isNotEmpty).toList(growable: false);

    final cleanedLimits = Map<String, num>.from(_limits)
      ..removeWhere((k, _) => k.trim().isEmpty);

    final initial = widget.initial;
    final plan = Plan(
      id: initial?.id ?? '',
      name: name,
      price: price,
      description: description,
      isActive: _isActive,
      durationDays: duration,
      features: cleanedFeatures,
      limits: cleanedLimits,
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
    );

    Navigator.of(context).pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupFeatures(widget.availableFeatures);
    final limitKeys = _limits.keys.toList(growable: false)..sort();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: _editing ? 'Edit Subscription Plan' : 'Create New Plan',
              subtitle: 'Configure features, pricing, and usage limits for this tier.',
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
                        title: 'PLAN DETAILS',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    controller: _name,
                                    label: 'Label',
                                    hintText: 'e.g. Enterprise Plus',
                                    prefixIcon: Icons.workspace_premium_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _price,
                                    label: 'Unit Price (PKR)',
                                    hintText: '0.00',
                                    prefixIcon: Icons.payments_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _duration,
                                    label: 'Validity (Days)',
                                    hintText: '365',
                                    prefixIcon: Icons.calendar_month_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _ActiveToggle(
                                  value: _isActive,
                                  onChanged: (v) => setState(() => _isActive = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextArea(
                              controller: _description,
                              label: 'Plan Description',
                              hintText: 'Describe the features and benefits of this plan.',
                              minLines: 2,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 1,
                      child: _GroupCard(
                        title: 'FEATURES & ACCESS',
                        child: grouped.isEmpty
                            ? const _EmptyFeatures()
                            : ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 380),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: grouped.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final entry = grouped[index];
                                    return _FeatureGroupTile(
                                      group: entry.$1,
                                      items: entry.$2,
                                      selected: _features,
                                      onSelectAll: (enabled) {
                                        setState(() {
                                          if (enabled) {
                                            for (final f in entry.$2) {
                                              _features.add(f.key);
                                            }
                                          } else {
                                            for (final f in entry.$2) {
                                              _features.remove(f.key);
                                            }
                                          }
                                        });
                                      },
                                      onToggle: (key, enabled) {
                                        setState(() {
                                          if (enabled) {
                                            _features.add(key);
                                          } else {
                                            _features.remove(key);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideIn(
                      delayIndex: 2,
                      child: _GroupCard(
                        title: 'RESOURCE CONSTRAINTS',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _newLimitKey,
                                    label: 'Key',
                                    hintText: 'e.g. max_file_size',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 160,
                                  child: AppTextField(
                                    controller: _newLimitValue,
                                    label: 'Quota',
                                    hintText: '0',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: AppPrimaryButton(
                                    onPressed: _addLimit,
                                    label: 'Add Limit',
                                    icon: Icons.add_circle_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                            if (limitKeys.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 240),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: limitKeys.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final k = limitKeys[index];
                                    return _LimitTile(
                                      label: _prettyKey(k),
                                      value: _limits[k] ?? 0,
                                      onChanged: (next) =>
                                          setState(() => _limits[k] = next),
                                      onRemove: () => setState(() {
                                        _limits.remove(k);
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ],
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
            label: editing ? 'Update Plan' : 'Publish Plan',
            icon: editing ? Icons.update_rounded : Icons.publish_rounded,
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

class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppRadii.r12,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            color: value ? Colors.green : cs.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            value ? 'PUBLISHED' : 'DRAFT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.7,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _FeatureGroupTile extends StatefulWidget {
  const _FeatureGroupTile({
    required this.group,
    required this.items,
    required this.selected,
    required this.onSelectAll,
    required this.onToggle,
  });

  final String group;
  final List<FeatureFlag> items;
  final Set<String> selected;
  final ValueChanged<bool> onSelectAll;
  final void Function(String key, bool enabled) onToggle;

  @override
  State<_FeatureGroupTile> createState() => _FeatureGroupTileState();
}

class _FeatureGroupTileState extends State<_FeatureGroupTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = widget.items.length;
    final selectedCount =
        widget.items.where((f) => widget.selected.contains(f.key)).length;
    final bool? triState = selectedCount == 0
        ? false
        : (selectedCount == total ? true : null);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : AppRadii.r16,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.layers_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$selectedCount of $total active',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SelectionCounter(
                    triState: triState,
                    onChanged: (v) => widget.onSelectAll(v ?? true),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 64,
                ),
                itemBuilder: (context, i) {
                  final f = widget.items[i];
                  return _ToggleTile(
                    label: f.label.trim().isEmpty ? _prettyKey(f.key) : f.label,
                    subtitle: f.key,
                    value: widget.selected.contains(f.key),
                    onChanged: (enabled) => widget.onToggle(f.key, enabled),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.r12,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? cs.primary.withValues(alpha: 0.04) : cs.surface,
          borderRadius: AppRadii.r12,
          border: Border.all(
            color: value ? cs.primary.withValues(alpha: 0.2) : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.75,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({required this.triState, required this.onChanged});
  final bool? triState;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!(triState ?? false)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SELECT ALL',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: triState,
              tristate: true,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final num value;
  final ValueChanged<num> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          SizedBox(
            width: 120,
            child: AppTextField(
              label: 'Limit Value',
              initialValue: value.toString(),
              hintText: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = num.tryParse(v);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline_rounded,
                color: cs.error.withValues(alpha: 0.7), size: 20),
          ),
        ],
      ),
    );
  }
}

List<(String, List<FeatureFlag>)> _groupFeatures(List<FeatureFlag> items) {
  final Map<String, List<FeatureFlag>> grouped = {};
  for (final feature in items) {
    final group =
        feature.group.trim().isEmpty ? 'General' : feature.group.trim();
    grouped.putIfAbsent(group, () => []).add(feature);
  }
  final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return [
    for (final entry in entries)
      (
        entry.key,
        (entry.value
          ..sort((a, b) {
            final labelA = a.label.trim().isEmpty ? a.key : a.label;
            final labelB = b.label.trim().isEmpty ? b.key : b.label;
            return labelA.compareTo(labelB);
          }))
      )
  ];
}

class _EmptyFeatures extends StatelessWidget {
  const _EmptyFeatures();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No feature keys found. Add features in Feature Management first.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _prettyKey(String key) {
  final raw = key.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  if (raw.isEmpty) return key;
  final parts = raw.split(RegExp(r'\s+'));
  return parts
      .map((p) => p.isEmpty ? p : (p[0].toUpperCase() + p.substring(1)))
      .join(' ');
}
