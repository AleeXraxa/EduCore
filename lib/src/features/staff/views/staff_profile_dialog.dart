import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/staff/controllers/staff_controller.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class StaffProfileDialog extends StatefulWidget {
  const StaffProfileDialog({
    super.key,
    required this.staff,
    required this.controller,
  });

  final StaffMember staff;
  final StaffController controller;

  @override
  State<StaffProfileDialog> createState() => _StaffProfileDialogState();
}

class _StaffProfileDialogState extends State<StaffProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, minHeight: 600),
        child: Column(
          children: [
            _ProfileHeader(staff: widget.staff),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Profile Info'),
                Tab(text: 'Access Summary'),
                Tab(text: 'Activity Log'),
              ],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(staff: widget.staff),
                  _AccessTab(
                    staff: widget.staff,
                    controller: widget.controller,
                  ),
                  _ActivityTab(staffId: widget.staff.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.staff});
  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(40),
      color: cs.primaryContainer.withValues(alpha: 0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: cs.primary,
            child: Text(
              staff.name[0].toUpperCase(),
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Badge(label: staff.roleDisplayName, color: cs.primary),
                    const SizedBox(width: 8),
                    _Badge(
                      label: staff.isActive ? 'Active' : 'Blocked',
                      color: staff.isActive ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.staff});
  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoField(
            label: 'Full Name',
            value: staff.name,
            icon: Icons.person_outline_rounded,
          ),
          _InfoField(
            label: 'Email Address',
            value: staff.email,
            icon: Icons.email_outlined,
          ),
          _InfoField(
            label: 'Phone Number',
            value: staff.phone,
            icon: Icons.phone_outlined,
          ),
          _InfoField(
            label: 'Member Since',
            value: DateFormat('MMMM dd, yyyy').format(staff.createdAt),
            icon: Icons.calendar_today_rounded,
          ),
          _InfoField(
            label: 'Staff ID',
            value: staff.id,
            icon: Icons.fingerprint_rounded,
          ),
        ],
      ),
    );
  }
}

class _AccessTab extends StatelessWidget {
  const _AccessTab({required this.staff, required this.controller});
  final StaffMember staff;
  final StaffController controller;

  @override
  Widget build(BuildContext context) {
    // Resolve effective permissions
    final granted = controller.allFeatures.where((f) {
      // Priority 1: Explicit deny
      if (staff.deniedFeatureKeys.contains(f.key)) return false;
      // Priority 2: Explicit allow (Required for staff)
      return staff.assignedFeatureKeys.contains(f.key);
    }).toList();

    final denied = controller.allFeatures.where((f) {
      if (staff.deniedFeatureKeys.contains(f.key)) return true;
      if (granted.any((g) => g.key == f.key)) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        _PermissionSection(
          title: 'Access Granted',
          subtitle: 'Features this user can currently use',
          features: granted,
          isAllowed: true,
        ),
        const SizedBox(height: 32),
        _PermissionSection(
          title: 'Access Denied',
          subtitle: 'Features restricted via policy or plan',
          features: denied,
          isAllowed: false,
        ),
      ],
    );
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.isAllowed,
  });

  final String title;
  final String subtitle;
  final List<dynamic> features;
  final bool isAllowed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isAllowed ? const Color(0xFF10B981) : cs.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 16),
        if (features.isEmpty)
          Text(
            'No features in this category.',
            style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map((f) => _AccessChip(label: f.label, isAllowed: isAllowed))
                .toList(),
          ),
      ],
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.label, required this.isAllowed});
  final String label;
  final bool isAllowed;

  @override
  Widget build(BuildContext context) {
    final color = isAllowed ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAllowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuditLog>>(
      stream: AppServices.instance.auditLogService?.watchLogs(
        limit: 20,
      ).map((logs) => logs.where((l) => l.targetDoc == staffId).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No recent activity recorded.'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _ActivityTile(log: log);
          },
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log});
  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIcon(log.action), color: cs.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActionText(log.action),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Performed by ${log.userName}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          DateFormat('HH:mm, dd MMM').format(log.timestamp),
          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
        ),
      ],
    );
  }

  IconData _getIcon(String action) {
    switch (action) {
      case 'staff_create': return Icons.add_circle_outline_rounded;
      case 'permissions_update': return Icons.security_rounded;
      case 'staff_block': return Icons.block_rounded;
      case 'staff_unblock': return Icons.check_circle_outline_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'staff_create': return 'Staff member created';
      case 'permissions_update': return 'Permissions modified';
      case 'staff_block': return 'Staff member blocked';
      case 'staff_unblock': return 'Staff member unblocked';
      default: return action.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
