import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/features/classes/classes_controller.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:flutter/material.dart';

class AddEditClassDialog extends StatefulWidget {
  const AddEditClassDialog({
    super.key,
    required this.controller,
    this.existingClass,
  });

  final ClassesController controller;
  final InstituteClass? existingClass;

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sectionController;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _isActive = true;
  String? _selectedFeePlanId;
  String? _selectedFeePlanName;
  String? _errorMessage;
  bool _saving = false;

  List<FeePlan> _feePlans = [];
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingClass?.name ?? '',
    );
    _sectionController = TextEditingController(
      text: widget.existingClass?.section ?? '',
    );
    _selectedTeacherId = widget.existingClass?.classTeacherId;
    _selectedTeacherName = widget.existingClass?.classTeacherName;
    _selectedFeePlanId = widget.existingClass?.feePlanId;
    _selectedFeePlanName = widget.existingClass?.feePlanName;
    _isActive = widget.existingClass?.isActive ?? true;
    _loadFeePlans();
  }

  Future<void> _loadFeePlans() async {
    try {
      final plans = await AppServices.instance.feePlanService!.getFeePlans(
        AppServices.instance.authService?.session?.academyId ?? '',
      );
      if (mounted) {
        setState(() {
          _feePlans = plans.where((p) => p.isActive).toList();
          _loadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final section = _sectionController.text.trim();

    bool ok;
    try {
      if (widget.existingClass == null) {
        ok = await widget.controller.createClass(
          name: name,
          section: section,
          classTeacherId: _selectedTeacherId,
          classTeacherName: _selectedTeacherName,
          feePlanId: _selectedFeePlanId!,
          feePlanName: _selectedFeePlanName!,
        );
      } else {
        ok = await widget.controller.updateClass(
          classId: widget.existingClass!.id,
          name: name,
          section: section,
          classTeacherId: _selectedTeacherId,
          classTeacherName: _selectedTeacherName,
          feePlanId: _selectedFeePlanId,
          feePlanName: _selectedFeePlanName,
          isActive: _isActive,
        );
      }

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (e is PlanLimitExceededException) {
        AppDialogs.showLimitReached(
          context,
          message: e.message,
          onUpgrade: () {
            // TODO: Navigate to pricing/plans page
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existingClass != null;

    return Dialog(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit Class' : 'Create New Class',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEdit
                      ? 'Update details for this class.'
                      : 'Define a new class for your institute.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: AppRadii.r8,
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameController,
                  label: 'Class Name',
                  hintText: 'e.g. Grade 10',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Class Name is required'
                      : null,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _sectionController,
                  label: 'Section (Optional)',
                  hintText: 'e.g. A, B, North',
                ),
                const SizedBox(height: 24),

                if (_loadingPlans)
                  const Center(child: LinearProgressIndicator())
                else if (_feePlans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.1),
                      borderRadius: AppRadii.r12,
                      border: Border.all(color: cs.error),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No active Fee Plans found!',
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A Fee Plan is required before you can create a class.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  AppDropdown<String>(
                    label: 'Primary Fee Plan',
                    value: _selectedFeePlanId,
                    items: _feePlans.map((e) => e.id).toList(),
                    itemLabel: (id) =>
                        _feePlans.firstWhere((e) => e.id == id).name,
                    onChanged: (val) {
                      setState(() {
                        _selectedFeePlanId = val;
                        _selectedFeePlanName = _feePlans
                            .firstWhere((e) => e.id == val)
                            .name;
                      });
                    },
                    prefixIcon: Icons.payments_rounded,
                  ),

                if (isEdit) ...[
                  SwitchListTile.adaptive(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text(
                      'Active Status',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Class is currently active'
                          : 'Class is disabled',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: cs.primary,
                  ),
                ],
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppPrimaryButton(
                      onPressed:
                          (_saving ||
                              (_feePlans.isEmpty &&
                                  widget.existingClass == null))
                          ? () {}
                          : _save,
                      label: _saving
                          ? 'Saving...'
                          : (isEdit ? 'Save Changes' : 'Create Class'),
                      busy: _saving,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
