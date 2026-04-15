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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupFeatures(widget.availableFeatures);
    final limitKeys = _limits.keys.toList(growable: false)..sort();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editing ? 'Edit plan' : 'Create plan',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Plans define pricing and feature access for institutes.',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GroupCard(
                        title: 'Plan details',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _name,
                                    label: 'Plan name',
                                    hintText: 'e.g. Basic / Pro / Premium',
                                    prefixIcon: Icons.workspace_premium_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _price,
                                    label: 'Price (PKR)',
                                    hintText: 'e.g. 12000',
                                    prefixIcon: Icons.payments_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    controller: _duration,
                                    label: 'Duration (days)',
                                    hintText: 'e.g. 30',
                                    prefixIcon: Icons.calendar_month_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 190,
                                  child: _ActiveToggle(
                                    value: _isActive,
                                    onChanged: (v) =>
                                        setState(() => _isActive = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextArea(
                              controller: _description,
                              label: 'Description',
                              hintText:
                                  'Short plan description for admins and sales.',
                              minLines: 2,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GroupCard(
                        title: 'Features',
                        child: grouped.isEmpty
                            ? _EmptyFeatures()
                            : ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 360),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: grouped.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final entry = grouped[index];
                                    final group = entry.$1;
                                    final items = entry.$2;
                                    return _FeatureGroupTile(
                                      group: group,
                                      items: items,
                                      selected: _features,
                                      onSelectAll: (enabled) {
                                        setState(() {
                                          if (enabled) {
                                            for (final f in items) {
                                              _features.add(f.key);
                                            }
                                          } else {
                                            for (final f in items) {
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
                      const SizedBox(height: 12),
                      _GroupCard(
                        title: 'Limits (optional)',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newLimitKey,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Limit key (e.g. maxStudents)',
                                      filled: true,
                                      fillColor: cs.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadii.r12,
                                        borderSide: BorderSide(
                                          color: cs.outlineVariant,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadii.r12,
                                        borderSide: BorderSide(
                                          color: cs.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _newLimitValue,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Value',
                                      filled: true,
                                      fillColor: cs.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadii.r12,
                                        borderSide: BorderSide(
                                          color: cs.outlineVariant,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadii.r12,
                                        borderSide: BorderSide(
                                          color: cs.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AppPrimaryButton(
                                  onPressed: _addLimit,
                                  label: 'Add',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: limitKeys.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final k = limitKeys[index];
                                  final v = _limits[k] ?? 0;
                                  return _LimitTile(
                                    label: _prettyKey(k),
                                    value: v,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Feature keys are dynamic and can evolve as EduCore grows.',
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
                    onPressed: _submit,
                    icon: Icons.check_rounded,
                    label: _editing ? 'Save changes' : 'Create plan',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

    final cleanedFeatures = _features
        .where((k) => k.trim().isNotEmpty)
        .toList(growable: false);

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r12,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.power_settings_new_rounded, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ? 'Active' : 'Inactive',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
    final selectedCount = widget.items
        .where((f) => widget.selected.contains(f.key))
        .length;
    final bool? triState = selectedCount == 0
        ? false
        : (selectedCount == total ? true : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, color: cs.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$selectedCount of $total selected',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                'Select all',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 6),
              Checkbox(
                value: triState,
                tristate: true,
                onChanged: (v) {
                  widget.onSelectAll(v ?? true);
                  setState(() {});
                },
              ),
              IconButton(
                tooltip: _expanded ? 'Collapse group' : 'Expand group',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (final f in widget.items) ...[
                  _ToggleTile(
                    label: f.label.trim().isEmpty ? _prettyKey(f.key) : f.label,
                    subtitle: f.key,
                    value: widget.selected.contains(f.key),
                    onChanged: (enabled) {
                      widget.onToggle(f.key, enabled);
                      setState(() {});
                    },
                    onRemove: null,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered
        ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
        : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            if (widget.onRemove != null)
              IconButton(
                tooltip: 'Remove',
                onPressed: widget.onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            Switch(value: widget.value, onChanged: widget.onChanged),
          ],
        ),
      ),
    );
  }
}

class _LimitTile extends StatefulWidget {
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
  State<_LimitTile> createState() => _LimitTileState();
}

class _LimitTileState extends State<_LimitTile> {
  bool _hovered = false;
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(covariant _LimitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _hovered
        ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
        : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.r16,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = num.tryParse(v);
                  if (parsed == null) return;
                  widget.onChanged(parsed);
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remove',
              onPressed: widget.onRemove,
              icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

List<(String, List<FeatureFlag>)> _groupFeatures(List<FeatureFlag> items) {
  final Map<String, List<FeatureFlag>> grouped = {};
  for (final feature in items) {
    final group = feature.group.trim().isEmpty ? 'Ungrouped' : feature.group.trim();
    grouped.putIfAbsent(group, () => []).add(feature);
  }
  final entries = grouped.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return [
    for (final entry in entries)
      (
        entry.key,
        (entry.value..sort((a, b) {
          final labelA = a.label.trim().isEmpty ? a.key : a.label;
          final labelB = b.label.trim().isEmpty ? b.key : b.label;
          return labelA.compareTo(labelB);
        }))
      )
  ];
}

class _EmptyFeatures extends StatelessWidget {
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
