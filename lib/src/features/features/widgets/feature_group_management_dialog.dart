import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/features/features_controller.dart';
import 'package:educore/src/features/features/models/feature_group.dart';
import 'package:flutter/material.dart';

class FeatureGroupManagementDialog extends StatefulWidget {
  const FeatureGroupManagementDialog({super.key, required this.controller});

  final FeaturesController controller;

  static Future<void> show(
    BuildContext context, {
    required FeaturesController controller,
  }) async {
    await showDialog(
      context: context,
      builder: (context) =>
          FeatureGroupManagementDialog(controller: controller),
    );
  }

  @override
  State<FeatureGroupManagementDialog> createState() =>
      _FeatureGroupManagementDialogState();
}

class _FeatureGroupManagementDialogState
    extends State<FeatureGroupManagementDialog> {
  final _name = TextEditingController();
  final _icon = TextEditingController(text: 'folder');
  final _order = TextEditingController(text: '0');
  bool _isSystem = false;
  FeatureGroup? _editing;

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _order.dispose();
    super.dispose();
  }

  void _startEdit(FeatureGroup group) {
    setState(() {
      _editing = group;
      _name.text = group.name;
      _icon.text = group.icon;
      _order.text = group.order.toString();
      _isSystem = group.isSystem;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _name.clear();
      _icon.text = 'folder';
      _order.text = '0';
      _isSystem = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;

    try {
      if (_editing == null) {
        await widget.controller.createFeatureGroup(
          FeatureGroup(
            id: '',
            name: _name.text,
            icon: _icon.text,
            order: int.tryParse(_order.text) ?? 0,
            isSystem: _isSystem,
          ),
        );
      } else {
        await widget.controller.updateFeatureGroup(
          _editing!.copyWith(
            name: _name.text,
            icon: _icon.text,
            order: int.tryParse(_order.text) ?? 0,
            isSystem: _isSystem,
          ),
        );
      }
      _clear();
      if (mounted) {
        AppToasts.showSuccess(context, message: 'Group saved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context,
          title: 'Operation Failed',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = widget.controller.featureGroups;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Editor Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: cs.outlineVariant),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editing == null
                                    ? 'CREATE NEW GROUP'
                                    : 'EDIT GROUP',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: cs.primary,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              AppTextField(
                                controller: _name,
                                label: 'Group Name',
                                hintText: 'e.g. Academic',
                                prefixIcon: Icons.label_important_rounded,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _icon,
                                      label: 'Icon',
                                      prefixIcon: Icons.folder_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _order,
                                      label: 'Order',
                                      prefixIcon: Icons.sort_rounded,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                value: _isSystem,
                                onChanged: (v) =>
                                    setState(() => _isSystem = v ?? false),
                                title: const Text('System Protected'),
                                subtitle: const Text(
                                  'Prevents deletion by other admins',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadii.r12,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  if (_editing != null) ...[
                                    TextButton(
                                      onPressed: _clear,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: AppPrimaryButton(
                                      onPressed: widget.controller.busy
                                          ? null
                                          : _save,
                                      label: _editing == null
                                          ? 'Create Group'
                                          : 'Update Group',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // List Section
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: cs.surfaceContainerLowest,
                        child: groups.isEmpty
                            ? const Center(
                                child: Text('No formal groups defined yet.'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: groups.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final g = groups[index];
                                  final isEditing = _editing?.id == g.id;
                                  return _GroupTile(
                                    group: g,
                                    isEditing: isEditing,
                                    onEdit: () => _startEdit(g),
                                    onDelete: g.isSystem
                                        ? null
                                        : () => _delete(g),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(FeatureGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? Features assigned to this group will remain, but the group label will become implicit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.controller.deleteFeatureGroup(group.id);
        if (_editing?.id == group.id) _clear();
      } catch (e) {
        if (mounted) {
          AppDialogs.showError(
            context,
            title: 'Deletion Error',
            message: e.toString(),
          );
        }
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: AppRadii.r12,
            ),
            child: Icon(Icons.folder_copy_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Feature Groups',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Organize your platform capabilities into logical categories.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  final FeatureGroup group;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppAnimatedSlide(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEditing ? cs.primary.withValues(alpha: 0.05) : cs.surface,
          borderRadius: AppRadii.r12,
          border: Border.all(
            color: isEditing ? cs.primary : cs.outlineVariant,
            width: isEditing ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppRadii.r8,
              ),
              child: Text(
                group.order.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (group.isSystem) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                      ],
                    ],
                  ),
                  if (group.description.isNotEmpty)
                    Text(
                      group.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                color: cs.error,
              ),
          ],
        ),
      ),
    );
  }
}
