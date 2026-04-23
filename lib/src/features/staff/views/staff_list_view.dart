import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_action_menu.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/kpi_card.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/features/staff/controllers/staff_controller.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/features/staff/views/add_edit_staff_dialog.dart';
import 'package:educore/src/features/staff/views/manage_access_dialog.dart';
import 'package:educore/src/features/staff/views/staff_profile_dialog.dart';
import 'package:flutter/material.dart';

class StaffListView extends StatefulWidget {
  const StaffListView({super.key});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView> {
  late final StaffController _controller;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StaffController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditStaff([StaffMember? staff]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditStaffDialog(
        staff: staff,
        controller: _controller,
      ),
    );
  }

  void _showManageAccess(StaffMember staff) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManageAccessDialog(
        staff: staff,
        controller: _controller,
      ),
    );
  }

  void _showStaffProfile(StaffMember staff) {
    showDialog(
      context: context,
      builder: (_) => StaffProfileDialog(
        staff: staff,
        controller: _controller,
      ),
    );
  }

  Future<void> _handleDelete(StaffMember staff) async {
    final confirmed = await AppDialogs.showDeleteConfirmation(
      context,
      message: 'Are you sure you want to delete ${staff.name}? This will permanently block their access.',
    );

    if (confirmed == true) {
      if (mounted) AppDialogs.showLoading(context, message: 'Deleting record...');
      await _controller.deleteStaff(staff.id);
      if (mounted) {
        AppDialogs.hideLoading(context);
        AppDialogs.showSuccess(
          context,
          title: 'Staff Deleted',
          message: 'Account for ${staff.name} has been removed.',
        );
      }
    }
  }

  Future<void> _handleToggleStatus(StaffMember staff) async {
    final newStatus = !staff.isActive;
    await _controller.toggleStatus(staff.id, newStatus);
    if (mounted) {
      AppToasts.showSuccess(
        context,
        message: 'Staff ${newStatus ? 'activated' : 'blocked'} successfully.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureSvc = AppServices.instance.featureAccessService;
    if (featureSvc == null || !featureSvc.canAccess('staff_view')) {
      return const AccessDeniedView(featureName: 'Staff Management');
    }
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<StaffController>(
      controller: _controller,
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.5),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StaffHeader(
                controller: controller,
                searchCtrl: _searchCtrl,
                onAddStaff: featureSvc.canAccess('staff_add') ? _showAddEditStaff : null,
              ),
              const Divider(height: 1),
              Expanded(
                child: controller.busy && controller.staffList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : controller.staffList.isEmpty
                        ? _EmptyStaff(onAdd: _showAddEditStaff)
                        : _StaffGrid(
                            staff: controller.staffList,
                            onView: _showStaffProfile,
                            onEdit: featureSvc.canAccess('staff_edit') ? _showAddEditStaff : null,
                            onManageAccess: featureSvc.canAccess('role_management') ? _showManageAccess : null,
                            onStatusToggle: featureSvc.canAccess('staff_edit') ? _handleToggleStatus : null,
                            onDelete: featureSvc.canAccess('staff_delete') ? _handleDelete : null,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffHeader extends StatelessWidget {
  const _StaffHeader({
    required this.controller,
    required this.searchCtrl,
    this.onAddStaff,
  });

  final StaffController controller;
  final TextEditingController searchCtrl;
  final VoidCallback? onAddStaff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = screenSizeForWidth(MediaQuery.sizeOf(context).width) != ScreenSize.compact;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Staff Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
              ),
              const Spacer(),
              if (isDesktop && onAddStaff != null)
                FilledButton.icon(
                  onPressed: onAddStaff,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Staff'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _StaffKPIs(controller: controller),
        ],
      ),
    );
  }
}

class _StaffKPIs extends StatelessWidget {
  const _StaffKPIs({required this.controller});
  final StaffController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = controller.staffList.length;
    final active = controller.staffList.where((s) => s.isActive).length;

    return Row(
      children: [
        Expanded(
          child: KpiCard(
            data: KpiCardData(
              label: 'Total Staff',
              value: total.toString(),
              icon: Icons.people_outline_rounded,
              gradient: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              trendText: 'Total staff registered',
              trendUp: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            data: KpiCardData(
              label: 'Active Now',
              value: active.toString(),
              icon: Icons.check_circle_outline_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
              trendText: 'Ready to work',
              trendUp: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: KpiCard(
            data: KpiCardData(
              label: 'On Leave',
              value: '0',
              icon: Icons.event_busy_rounded,
              gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              trendText: 'Unavailable today',
              trendUp: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffGrid extends StatelessWidget {
  const _StaffGrid({
    required this.staff,
    required this.onView,
    this.onEdit,
    this.onManageAccess,
    required this.onStatusToggle,
    this.onDelete,
  });

  final List<StaffMember> staff;
  final Function(StaffMember) onView;
  final Function(StaffMember)? onEdit;
  final Function(StaffMember)? onManageAccess;
  final Function(StaffMember)? onStatusToggle;
  final Function(StaffMember)? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = staff[index];
        return _StaffCard(
          member: member,
          onView: () => onView(member),
          onEdit: onEdit != null ? () => onEdit!(member) : null,
          onManageAccess: onManageAccess != null ? () => onManageAccess!(member) : null,
          onStatusToggle: onStatusToggle != null ? () => onStatusToggle!(member) : null,
          onDelete: onDelete != null ? () => onDelete!(member) : null,
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.onView,
    this.onEdit,
    this.onManageAccess,
    required this.onStatusToggle,
    this.onDelete,
  });

  final StaffMember member;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onManageAccess;
  final VoidCallback? onStatusToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _RoleBadge(role: member.roleDisplayName),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(member.phone, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusIndicator(isActive: member.isActive),
            const SizedBox(width: 16),
            AppActionMenu(
              actions: [
                AppActionItem(
                  label: 'View Profile',
                  icon: Icons.visibility_outlined,
                  onTap: onView,
                ),
                if (onEdit != null)
                  AppActionItem(
                    label: 'Edit Details',
                    icon: Icons.edit_outlined,
                    onTap: onEdit!,
                  ),
                if (onManageAccess != null)
                  AppActionItem(
                    label: 'Manage Access',
                    icon: Icons.lock_open_rounded,
                    onTap: onManageAccess!,
                  ),
                if (onStatusToggle != null)
                  AppActionItem(
                    label: member.isActive ? 'Block Staff' : 'Unblock Staff',
                    icon: member.isActive ? Icons.block_rounded : Icons.check_circle_outline,
                    onTap: onStatusToggle!,
                  ),
                if (onDelete != null)
                  AppActionItem(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    type: AppActionType.delete,
                    onTap: onDelete!,
                  ),
              ],
            ),
          ],
        ),
        onTap: onView,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: cs.onSecondaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? 'Active' : 'Blocked',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptyStaff extends StatelessWidget {
  const _EmptyStaff({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No staff members found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Create your first staff account to start delegating.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }
}
