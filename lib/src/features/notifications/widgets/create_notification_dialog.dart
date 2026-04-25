import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/notifications/notifications_controller.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';

class CreateNotificationDialog extends StatefulWidget {
  final NotificationsController controller;

  const CreateNotificationDialog({super.key, required this.controller});

  @override
  State<CreateNotificationDialog> createState() => _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<CreateNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isBroadcast = true;
  Academy? _selectedAcademy;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBroadcast && _selectedAcademy == null) {
      AppDialogs.showError(
        context,
        title: 'Target Required',
        message: 'Please select a specific institute to receive this targeted notification.',
      );
      return;
    }

    try {
      AppDialogs.showLoading(context, message: 'Sending notification...');
      if (_isBroadcast) {
        await widget.controller.sendBroadcast(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
        );
      } else {
        await widget.controller.sendTargeted(
          academyId: _selectedAcademy!.id,
          academyName: _selectedAcademy!.name,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
        );
      }

      if (mounted) {
        AppDialogs.hide(context);
        Navigator.of(context).pop();
        AppDialogs.showSuccess(
          context,
          title: 'Broadcast Sent',
          message: 'The notification has been successfully delivered to all intended recipients.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.hide(context);
        AppDialogs.showError(
          context,
          title: 'Delivery Failed',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Notification'),
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broadcast or Targeted?',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeSelectionCard(
                      label: 'All Institutes',
                      icon: Icons.campaign_rounded,
                      selected: _isBroadcast,
                      onTap: () => setState(() => _isBroadcast = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeSelectionCard(
                      label: 'Targeted',
                      icon: Icons.person_pin_rounded,
                      selected: !_isBroadcast,
                      onTap: () => setState(() => _isBroadcast = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_isBroadcast) ...[
                AppDropdown<Academy>(
                  label: 'Select Institute',
                  items: widget.controller.academies,
                  value: _selectedAcademy,
                  searchable: true,
                  prefixIcon: Icons.business_rounded,
                  itemLabel: (a) => a.name,
                  onChanged: (val) => setState(() => _selectedAcademy = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Scheduled Maintenance',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Type your message here...',
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.controller.isSending ? null : _handleSubmit,
          child: widget.controller.isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Notification'),
        ),
      ],
    );
  }
}

class _TypeSelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSelectionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? cs.primary.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
