import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/features/plans/models/plan.dart';
import 'package:flutter/material.dart';

class FeatureToggleDialog extends StatefulWidget {
  const FeatureToggleDialog({
    super.key,
    required this.plan,
    required this.onToggle,
    required this.availableKeys,
  });

  final Plan plan;
  final Future<void> Function(String key, bool enabled) onToggle;
  final List<String> availableKeys;

  static Future<void> show(
    BuildContext context, {
    required Plan plan,
    required Future<void> Function(String key, bool enabled) onToggle,
    required List<String> availableKeys,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FeatureToggleDialog(
        plan: plan,
        onToggle: onToggle,
        availableKeys: availableKeys,
      ),
    );
  }

  @override
  State<FeatureToggleDialog> createState() => _FeatureToggleDialogState();
}

class _FeatureToggleDialogState extends State<FeatureToggleDialog> {
  late Set<String> _enabledKeys;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _enabledKeys = {...widget.plan.features};
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keys = widget.availableKeys.toList(growable: false)..sort();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
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
                          'Features',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enable or disable features for "${widget.plan.name}".',
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
              if (keys.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
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
                ),
              if (keys.isNotEmpty) const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final k = keys[index];
                    final enabled = _enabledKeys.contains(k);
                    return _FeatureRow(
                      keyName: k,
                      enabled: enabled,
                      busy: _busy,
                      onChanged: (v) => _toggle(k, v),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Changes are saved instantly.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      if (value) {
        _enabledKeys.add(key);
      } else {
        _enabledKeys.remove(key);
      }
    });
    setState(() => _busy = true);
    try {
      await widget.onToggle(key, value);
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

}

class _FeatureRow extends StatefulWidget {
  const _FeatureRow({
    required this.keyName,
    required this.enabled,
    required this.busy,
    required this.onChanged,
  });

  final String keyName;
  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow> {
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
              child: Text(
                _prettyKey(widget.keyName),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
              ),
            ),
            Switch(
              value: widget.enabled,
              onChanged: widget.busy ? null : widget.onChanged,
            ),
          ],
        ),
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
