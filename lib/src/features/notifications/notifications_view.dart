import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_multi_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_area.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/notifications/models/admin_notification.dart';
import 'package:educore/src/features/notifications/notifications_controller.dart';
import 'package:educore/src/features/notifications/widgets/notification_details_dialog.dart';
import 'package:educore/src/features/notifications/widgets/notifications_table.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificationsController _controller;

  final _title = TextEditingController();
  final _message = TextEditingController();

  AdminNotificationType _type = AdminNotificationType.announcement;
  AdminNotificationAudience _audience = AdminNotificationAudience.allInstitutes;
  List<String> _targets = const [];

  bool _schedule = false;
  DateTime? _scheduledFor;

  @override
  void initState() {
    super.initState();
    _controller = NotificationsController();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const toolbarHeight = 48.0;

    return ControllerBuilder<NotificationsController>(
      controller: _controller,
      builder: (context, controller, _) {
        final history = controller.history;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedSlideIn(
                delayIndex: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send announcements and alerts to institutes with confidence.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: toolbarHeight,
                      child: HoverScale(
                        child: AppPrimaryButton(
                          label: 'Send Notification',
                          icon: Icons.send_rounded,
                          busy: controller.busy,
                          onPressed: _onSend,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _AnimatedSlideIn(
                delayIndex: 1,
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compose Message',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a message and choose audience + schedule.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoCol = constraints.maxWidth >= 980;
                          const fieldHeight = 56.0;
                          return Column(
                            children: [
                              Flex(
                                direction: twoCol ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: fieldHeight,
                                      child: AppTextField(
                                        controller: _title,
                                        label: 'Title',
                                        hintText: 'e.g. System upgrade scheduled',
                                        prefixIcon: Icons.title_rounded,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: twoCol ? 12 : 0,
                                    height: twoCol ? 0 : 12,
                                  ),
                                  SizedBox(
                                    width: twoCol ? 280 : double.infinity,
                                    child: SizedBox(
                                      height: fieldHeight,
                                      child: AppDropdown<AdminNotificationType>(
                                        label: 'Type',
                                        showLabel: false,
                                        compact: true,
                                        hintText: 'Type',
                                        items: const [
                                          AdminNotificationType.announcement,
                                          AdminNotificationType.reminder,
                                          AdminNotificationType.alert,
                                        ],
                                        value: _type,
                                        itemLabel: (t) => switch (t) {
                                          AdminNotificationType.announcement =>
                                            'Announcement',
                                          AdminNotificationType.reminder =>
                                            'Reminder',
                                          AdminNotificationType.alert => 'Alert',
                                        },
                                        prefixIcon: Icons.category_rounded,
                                        onChanged: (v) => setState(
                                          () => _type = v ?? _type,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextArea(
                                controller: _message,
                                label: 'Message',
                                hintText:
                                    'Write a clear message. Keep it short and action-oriented.',
                                minLines: 5,
                                maxLines: 8,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_message.text.length} / 500 characters',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flex(
                                direction: twoCol ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: fieldHeight,
                                      child: AppDropdown<AdminNotificationAudience>(
                                        label: 'Audience',
                                        showLabel: false,
                                        compact: true,
                                        hintText: 'Audience',
                                        items: const [
                                          AdminNotificationAudience.allInstitutes,
                                          AdminNotificationAudience.specificInstitutes,
                                        ],
                                        value: _audience,
                                        prefixIcon: Icons.groups_rounded,
                                        itemLabel: (a) => switch (a) {
                                          AdminNotificationAudience.allInstitutes =>
                                            'All institutes',
                                          AdminNotificationAudience.specificInstitutes =>
                                            'Specific institutes',
                                        },
                                        onChanged: (v) => setState(() {
                                          _audience = v ?? _audience;
                                          if (_audience ==
                                              AdminNotificationAudience
                                                  .allInstitutes) {
                                            _targets = const [];
                                          }
                                        }),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: twoCol ? 12 : 0,
                                    height: twoCol ? 0 : 12,
                                  ),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 180),
                                      child: _audience ==
                                              AdminNotificationAudience
                                                  .specificInstitutes
                                          ? SizedBox(
                                              key: const ValueKey('multi'),
                                              height: fieldHeight,
                                              child: AppMultiDropdown<String>(
                                                label: 'Institutes',
                                                showLabel: false,
                                                compact: true,
                                                items: controller.institutes,
                                                values: _targets,
                                                hintText: 'Institutes',
                                                prefixIcon: Icons.apartment_rounded,
                                                itemLabel: (s) => s,
                                                onChanged: (v) =>
                                                    setState(() => _targets = v),
                                              ),
                                            )
                                          : SizedBox(
                                              key: const ValueKey('all'),
                                              height: fieldHeight,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cs.surfaceContainerHighest
                                                      .withValues(alpha: 0.26),
                                                  borderRadius: AppRadii.r16,
                                                  border: Border.all(
                                                    color: cs.outlineVariant,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: cs.primary
                                                            .withValues(alpha: 0.10),
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(
                                                        Icons.public_rounded,
                                                        color: cs.primary,
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        'Delivered to all active institutes',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight.w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ScheduleRow(
                                      enabled: _schedule,
                                      when: _scheduledFor,
                                      onToggle: (v) => setState(() {
                                        _schedule = v;
                                        if (!v) _scheduledFor = null;
                                      }),
                                      onPick: () => _pickSchedule(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _AnimatedSlideIn(
                delayIndex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispatch History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review previously sent announcements and alerts.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    NotificationsTable(
                      items: history,
                      onAction: (action) {
                        final n = history
                            .firstWhere((e) => e.id == action.notificationId);
                        switch (action.action) {
                          case NotificationMenuAction.view:
                            NotificationDetailsDialog.show(
                              context,
                              notification: n,
                              onResend: () => controller.resend(n.id),
                              onDelete: () => controller.delete(n.id),
                            );
                            break;
                          case NotificationMenuAction.resend:
                            controller.resend(n.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Resent: ${n.title}')),
                            );
                            break;
                          case NotificationMenuAction.delete:
                            controller.delete(n.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted: ${n.title}')),
                            );
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'SECURITY: Notifications are broadcast instantly. Review content carefully before dispatch.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSend() async {
    final title = _title.text.trim();
    final message = _message.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add title and message.')),
      );
      return;
    }
    if (message.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message too long (max 500).')),
      );
      return;
    }
    if (_audience == AdminNotificationAudience.specificInstitutes &&
        _targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one institute.')),
      );
      return;
    }
    if (_schedule && _scheduledFor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a schedule date/time.')),
      );
      return;
    }

    await _controller.send(
      title: title,
      message: message,
      type: _type,
      audience: _audience,
      targets: _targets,
      scheduledFor: _schedule ? _scheduledFor : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_schedule ? 'Scheduled' : 'Sent')),
    );
    _title.clear();
    _message.clear();
    setState(() {
      _type = AdminNotificationType.announcement;
      _audience = AdminNotificationAudience.allInstitutes;
      _targets = const [];
      _schedule = false;
      _scheduledFor = null;
    });
  }

  Future<void> _pickSchedule(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledFor ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledFor ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledFor = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _schedule = true;
    });
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



class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.enabled,
    required this.when,
    required this.onToggle,
    required this.onPick,
  });

  final bool enabled;
  final DateTime? when;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = when == null ? 'Not scheduled' : _fmtDateTime(when!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule (optional)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: enabled ? onPick : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Pick'),
          ),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd • $hh:$mi';
}
