import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/features/notifications/models/admin_notification.dart';
import 'package:educore/src/features/notifications/widgets/notification_status_badge.dart';
import 'package:educore/src/features/notifications/widgets/notification_type_pill.dart';
import 'package:flutter/material.dart';

class NotificationsTable extends StatelessWidget {
  const NotificationsTable({
    super.key,
    required this.items,
    required this.onAction,
  });

  final List<AdminNotification> items;
  final ValueChanged<NotificationRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 1080 ? 1080.0 : constraints.maxWidth;
        final cs = Theme.of(context).colorScheme;

        return AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    const _Header(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.75),
                    ),
                    if (items.isEmpty)
                      const _Empty()
                    else
                      for (var i = 0; i < items.length; i++)
                        _Row(
                          index: i,
                          item: items[i],
                          onAction: onAction,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
        child: const Row(
          children: [
            Expanded(flex: 30, child: Text('Title')),
            Expanded(flex: 14, child: Text('Type')),
            Expanded(flex: 16, child: Text('Target')),
            Expanded(
              flex: 14,
              child: Align(alignment: Alignment.centerRight, child: Text('Sent')),
            ),
            Expanded(flex: 12, child: Text('Status')),
            SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.index, required this.item, required this.onAction});

  final int index;
  final AdminNotification item;
  final ValueChanged<NotificationRowAction> onAction;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    final zebra = widget.index.isOdd
        ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
        : cs.surface;

    final scheduled = item.status == AdminNotificationStatus.scheduled;
    final scheduledBg = cs.primary.withValues(alpha: 0.03);

    final bg = _hovered
        ? cs.primary.withValues(alpha: 0.040)
        : (scheduled ? scheduledBg : zebra);

    final target = item.audience == AdminNotificationAudience.allInstitutes
        ? 'All institutes'
        : '${item.targets.length} institutes';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 30,
              child: _PrimaryCell(
                title: item.title,
                subtitle: _truncate(item.message),
              ),
            ),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminNotificationTypePill(type: item.type),
              ),
            ),
            Expanded(
              flex: 16,
              child: Text(
                target,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fmtDateTime(item.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AdminNotificationStatusBadge(status: item.status),
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<NotificationMenuAction>(
                  tooltip: 'Actions',
                  onSelected: (action) => widget.onAction(
                    NotificationRowAction(action, item.id),
                  ),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: NotificationMenuAction.view,
                      child: _MenuRow(
                        icon: Icons.visibility_rounded,
                        label: 'View details',
                      ),
                    ),
                    PopupMenuItem(
                      value: NotificationMenuAction.resend,
                      child: _MenuRow(
                        icon: Icons.refresh_rounded,
                        label: 'Resend',
                      ),
                    ),
                    PopupMenuItem(
                      value: NotificationMenuAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        danger: true,
                      ),
                    ),
                  ],
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                      color: cs.surface,
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.danger = false});

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? const Color(0xFFB91C1C) : cs.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _PrimaryCell extends StatelessWidget {
  const _PrimaryCell({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(
              Icons.campaign_rounded,
              color: cs.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send your first announcement to institutes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _truncate(String s) {
  final t = s.trim().replaceAll('\n', ' ');
  if (t.length <= 70) return t;
  return '${t.substring(0, 70)}…';
}

String _fmtDateTime(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd • $hh:$mi';
}

enum NotificationMenuAction { view, resend, delete }

@immutable
class NotificationRowAction {
  const NotificationRowAction(this.action, this.notificationId);

  final NotificationMenuAction action;
  final String notificationId;
}

