import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:flutter/material.dart';

class AssignFeePlanDialog extends StatefulWidget {
  final Student student;

  const AssignFeePlanDialog({super.key, required this.student});

  @override
  State<AssignFeePlanDialog> createState() => _AssignFeePlanDialogState();
}

class _AssignFeePlanDialogState extends State<AssignFeePlanDialog> {
  final _studentService = AppServices.instance.studentService;
  final _feePlanService = AppServices.instance.feePlanService;
  final _auth = AppServices.instance.authService;

  List<FeePlan> _plans = [];
  FeePlan? _selectedPlan;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final academyId = _auth?.currentAcademyId;
    if (academyId == null) return;

    try {
      final plans = await _feePlanService!.getFeePlans(academyId);
      setState(() {
        _plans = plans;
        if (widget.student.feePlanId.isNotEmpty) {
          _selectedPlan = plans.cast<FeePlan?>().firstWhere(
                (p) => p?.id == widget.student.feePlanId,
                orElse: () => null,
              );
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, title: 'Error', message: 'Failed to load fee plans: $e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedPlan == null) return;
    
    final academyId = _auth?.currentAcademyId;
    if (academyId == null) return;

    setState(() => _busy = true);
    try {
      await _studentService!.assignFeePlan(
        academyId: academyId,
        student: widget.student,
        plan: _selectedPlan!,
      );
      if (mounted) {
        Navigator.pop(context, true);
        AppDialogs.showSuccess(context, title: 'Success', message: 'Fee plan assigned successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, title: 'Error', message: 'Assignment failed: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Assign Fee Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a fee plan for ${widget.student.name}. This will update their billing mode and future fee generation.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              AppDropdown<FeePlan>(
                label: 'Select Fee Plan',
                items: _plans,
                value: _selectedPlan,
                itemLabel: (p) => '${p.name} (${p.planType.name.toUpperCase()})',
                onChanged: (p) => setState(() => _selectedPlan = p),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Assign Plan',
                    busy: _busy,
                    onPressed: _selectedPlan == null ? null : _handleAssign,
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
