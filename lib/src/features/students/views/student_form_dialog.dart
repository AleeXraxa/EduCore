import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';

import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';

class StudentFormDialog extends StatefulWidget {
  const StudentFormDialog({super.key, this.student, required this.controller});

  final Student? student;
  final StudentController controller;

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _fatherNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _rollNoCtrl;
  late String _selectedClassId;
  late String _selectedFeePlanId;
  String? _selectedFeePlanName;
  late String _status;
  bool _isLoading = false;
  bool _isFetching = true;

  List<InstituteClass> _availableClasses = [];
  List<FeePlan> _availableFeePlans = [];
  final Map<String, TextEditingController> _dynamicControllers = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student?.name ?? '');
    _fatherNameCtrl = TextEditingController(
      text: widget.student?.fatherName ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.student?.phone ?? '');
    _rollNoCtrl = TextEditingController(text: widget.student?.rollNo ?? '');
    _selectedClassId = widget.student?.classId ?? '';
    _selectedFeePlanId = widget.student?.feePlanId ?? '';
    _selectedFeePlanName = widget.student?.feePlanName;
    _status = widget.student?.status ?? 'active';

    _fetchInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.resetDynamicForm(widget.student?.customFields);
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isFetching = true);
    final academyId = AppServices.instance.authService!.session!.academyId;

    final List<Future<dynamic>> futures = [
      AppServices.instance.classService!.getClasses(academyId),
      AppServices.instance.feePlanService!.getFeePlans(academyId),
    ];

    if (widget.student == null && _rollNoCtrl.text.isEmpty) {
      futures.add(widget.controller.getNextRollNumber());
    }

    final results = await Future.wait(futures);
    final classes = results[0] as List<InstituteClass>;
    final plans = results[1] as List<FeePlan>;

    if (mounted) {
      setState(() {
        _isFetching = false;
        _availableClasses = classes;
        _availableFeePlans = plans.where((p) => p.isActive).toList();

        if (widget.student == null && results.length > 2) {
          _rollNoCtrl.text = results[2] as String;
        }

        if (_selectedClassId.isEmpty && classes.isNotEmpty) {
          _selectedClassId = classes.first.id;
          debugPrint(
            'StudentFormDialog: Auto-selected class: ${classes.first.name}',
          );
          // Auto-fill fee plan from class
          if (classes.first.feePlanId != null &&
              classes.first.feePlanId!.isNotEmpty) {
            final planId = classes.first.feePlanId!;
            if (_availableFeePlans.any((p) => p.id == planId)) {
              _selectedFeePlanId = planId;
              _selectedFeePlanName = classes.first.feePlanName;
              debugPrint(
                'StudentFormDialog: Auto-filled fee plan from class: $_selectedFeePlanId',
              );
            } else {
              debugPrint(
                'StudentFormDialog: Default plan $planId not found in active plans',
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _phoneCtrl.dispose();
    for (var ctrl in _dynamicControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    debugPrint('StudentFormDialog: _submit called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('StudentFormDialog: _formKey.validate() returned false');
      return;
    }

    final isEditing = widget.student != null;

    // STEP 1: Confirmation
    final confirmed = isEditing
        ? await AppDialogs.showEditConfirmation(context)
        : await AppDialogs.showAddConfirmation(context);

    if (confirmed != true) return;

    debugPrint('StudentFormDialog: Validation passed, starting save...');

    // STEP 2: Loading State
    if (mounted) {
      AppDialogs.showLoading(
        context,
        message: isEditing ? 'Updating record...' : 'Adding record...',
      );
    }

    final selectedClass = _availableClasses.firstWhere(
      (c) => c.id == _selectedClassId,
      orElse: () =>
          const InstituteClass(id: '', name: 'Unknown', subjectIds: []),
    );

    final newStudent = Student(
      id: widget.student?.id ?? '',
      name: _nameCtrl.text.trim(),
      fatherName: _fatherNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      rollNo: _rollNoCtrl.text.trim(),
      classId: _selectedClassId,
      className: selectedClass.displayName,
      admissionDate: widget.student?.admissionDate ?? DateTime.now(),
      status: _status,
      feePlanId: _selectedFeePlanId,
      feePlanName: _selectedFeePlanName,
      createdAt: widget.student?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      customFields: Map<String, dynamic>.from(
        widget.controller.dynamicFormState,
      ),
    );

    try {
      bool success;
      if (widget.student == null) {
        success = await widget.controller.addStudent(newStudent);
      } else {
        success = await widget.controller.updateStudent(newStudent);
      }

      // STEP 3: Success or Error Feedback
      if (mounted) {
        AppDialogs.hideLoading(context);

        if (success) {
          Navigator.of(context).pop(); // Close form
          AppDialogs.showSuccess(
            context,
            title: isEditing ? 'Update Successful' : 'Enrollment Complete',
            message: isEditing
                ? 'Student information has been updated.'
                : 'Student has been successfully enrolled in ${selectedClass.name}.',
          );
        } else {
          AppDialogs.showError(
            context,
            title: 'Operation Failed',
            message: 'Unable to save student records. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.hideLoading(context);

        if (e is PlanLimitExceededException) {
          AppDialogs.showLimitReached(
            context,
            message: e.message,
            onUpgrade: () {
              // TODO: Navigate to pricing
            },
          );
        } else {
          AppDialogs.showError(
            context,
            title: 'System Error',
            message: e.toString(),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.student != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.person_add_rounded,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Profile' : 'New Enrollment',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          isEditing
                              ? 'Update student details'
                              : 'Add a new student to system',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('PERSONAL INFORMATION'),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Student Full Name',
                        hint: 'Enter official name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _fatherNameCtrl,
                        label: 'Father\'s Name',
                        hint: 'Enter guardian name',
                        icon: Icons.family_restroom_outlined,
                        validator: (v) =>
                            v!.isEmpty ? 'Father name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _rollNoCtrl,
                        label: 'Roll Number (System Generated)',
                        hint: 'Roll #',
                        icon: Icons.tag_rounded,
                        readOnly: true,
                        validator: (v) =>
                            v!.isEmpty ? 'Roll Number is required' : null,
                      ),

                      const SizedBox(height: 32),
                      _sectionTitle('ENROLLMENT DETAILS'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _isFetching
                                ? const Center(child: LinearProgressIndicator())
                                : _availableClasses.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.errorContainer.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: AppRadii.r12,
                                      border: Border.all(color: cs.error),
                                    ),
                                    child: Text(
                                      'NO CLASSES FOUND. Create a class first.',
                                      style: TextStyle(
                                        color: cs.error,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : AppDropdown<String>(
                                    value: _selectedClassId,
                                    label: 'Class',
                                    prefixIcon: Icons.school_outlined,
                                    items: _availableClasses
                                        .map((e) => e.id)
                                        .toList(),
                                    itemLabel: (id) => _availableClasses
                                        .firstWhere((e) => e.id == id)
                                        .displayName,
                                    onChanged: (v) {
                                      debugPrint(
                                        'StudentFormDialog: Class selected: $v',
                                      );
                                      setState(() {
                                        _selectedClassId = v!;
                                        // Auto-fetch fee plan from class for new students
                                        if (widget.student == null) {
                                          final cls = _availableClasses
                                              .firstWhere((c) => c.id == v);
                                          debugPrint(
                                            'StudentFormDialog: Class default plan: ${cls.feePlanId}',
                                          );
                                          if (cls.feePlanId != null &&
                                              cls.feePlanId!.isNotEmpty) {
                                            final planId = cls.feePlanId!;
                                            if (_availableFeePlans.any(
                                              (p) => p.id == planId,
                                            )) {
                                              _selectedFeePlanId = planId;
                                              _selectedFeePlanName =
                                                  cls.feePlanName;
                                              debugPrint(
                                                'StudentFormDialog: Setting _selectedFeePlanId to $_selectedFeePlanId',
                                              );
                                            } else {
                                              debugPrint(
                                                'StudentFormDialog: Default plan $planId for selected class not found in active plans',
                                              );
                                              _selectedFeePlanId = '';
                                              _selectedFeePlanName = null;
                                            }
                                          }
                                        }
                                      });
                                    },
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _availableFeePlans.isEmpty && !isEditing
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.errorContainer.withValues(alpha: 0.1),
                                borderRadius: AppRadii.r12,
                                border: Border.all(
                                  color: cs.error.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: cs.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'A Fee Plan is REQUIRED. Please create a Fee Plan in the Fees module first.',
                                      style: TextStyle(
                                        color: cs.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AppDropdown<String>(
                              value: _selectedFeePlanId.isEmpty
                                  ? null
                                  : _selectedFeePlanId,
                              label: 'Fee Plan',
                              prefixIcon: Icons.payments_outlined,
                              items: _availableFeePlans
                                  .map((e) => e.id)
                                  .toList(),
                              itemLabel: (id) => _availableFeePlans
                                  .firstWhere((p) => p.id == id)
                                  .name,
                              onChanged: (v) {
                                setState(() {
                                  _selectedFeePlanId = v ?? '';
                                  if (_selectedFeePlanId.isNotEmpty) {
                                    final plan = _availableFeePlans.firstWhere(
                                      (p) => p.id == v,
                                    );
                                    _selectedFeePlanName = plan.name;
                                  } else {
                                    _selectedFeePlanName = null;
                                  }
                                });
                              },
                            ),

                      if (_selectedFeePlanId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildBillingHint(),
                        ),

                      const SizedBox(height: 20),
                      _buildField(
                        controller: _phoneCtrl,
                        label: 'Contact Number',
                        hint: '03XX XXXXXXX',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!RegExp(r'^03\d{9}$').hasMatch(val.trim())) {
                            return 'Enter valid 11-digit mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) => _customFieldsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(32),
              child: FilledButton(
                onPressed:
                    (_selectedClassId.isEmpty ||
                        _selectedFeePlanId.isEmpty)
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Profile' : 'Enroll Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: cs.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _customFieldsSection() {
    final definitions = widget.controller.customFieldDefinitions;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('ADDITIONAL INFORMATION'),
            TextButton.icon(
              onPressed: _showAddCustomFieldDialog,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Field'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (definitions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No custom fields yet. Click "Add Field" to grow your data schema.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ...definitions.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildDynamicField(field),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicField(StudentCustomField field) {
    final value = widget.controller.dynamicFormState[field.key];

    switch (field.type) {
      case CustomFieldType.text:
      case CustomFieldType.number:
        final ctrl = _dynamicControllers.putIfAbsent(
          field.key,
          () => TextEditingController(text: value?.toString() ?? ''),
        );

        return _buildField(
          controller: ctrl,
          label: field.label,
          hint: 'Enter ${field.label.toLowerCase()}',
          icon: field.type == CustomFieldType.number
              ? Icons.numbers_rounded
              : Icons.text_fields_rounded,
          keyboardType: field.type == CustomFieldType.number
              ? TextInputType.number
              : TextInputType.text,
          validator: field.isRequired
              ? (v) => v!.isEmpty ? 'Required' : null
              : null,
          onChanged: (v) => widget.controller.updateDynamicField(field.key, v),
        );
      case CustomFieldType.date:
        return _buildDateField(field);
      case CustomFieldType.dropdown:
        return AppDropdown<String>(
          value: value ?? (field.options.isNotEmpty ? field.options.first : ''),
          label: field.label,
          prefixIcon: Icons.list_rounded,
          items: field.options,
          itemLabel: (v) => v,
          onChanged: (v) => widget.controller.updateDynamicField(field.key, v),
        );
    }
  }

  Widget _buildDateField(StudentCustomField field) {
    final value = widget.controller.dynamicFormState[field.key];
    final dateStr = value is DateTime
        ? DateFormat('yyyy-MM-dd').format(value)
        : (value?.toString() ?? 'Select Date');
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value is DateTime ? value : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              widget.controller.updateDynamicField(field.key, picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: cs.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: value == null ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCustomFieldDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddCustomFieldDefinitionDialog(
        onSave: (field) {
          widget.controller.addCustomFieldDefinition(field);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: cs.primary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingHint() {
    final plan = _availableFeePlans.firstWhere(
      (p) => p.id == _selectedFeePlanId,
    );
    final cs = Theme.of(context).colorScheme;
    final isPkg = plan.planType == FeePlanType.package;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: AppRadii.r16,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPkg ? Icons.inventory_2_outlined : Icons.event_repeat_rounded,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isPkg ? 'ONE-TIME PACKAGE' : 'MONTHLY SUBSCRIPTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _hintStat(
                'Admission',
                '${plan.currency} ${plan.admissionFee.toStringAsFixed(0)}',
              ),
              _hintStat(
                isPkg ? 'Total Fee' : 'Monthly Fee',
                '${plan.currency} ${(isPkg ? plan.totalCourseFee : plan.monthlyFee).toStringAsFixed(0)}',
              ),
              if (isPkg)
                _hintStat('Duration', '${plan.durationMonths ?? 0}m')
              else
                _hintStat('Due Day', 'Day ${plan.monthlyDueDay}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hintStat(String label, String val) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _AddCustomFieldDefinitionDialog extends StatefulWidget {
  final Function(StudentCustomField) onSave;
  const _AddCustomFieldDefinitionDialog({required this.onSave});

  @override
  State<_AddCustomFieldDefinitionDialog> createState() =>
      __AddCustomFieldDefinitionDialogState();
}

class __AddCustomFieldDefinitionDialogState
    extends State<_AddCustomFieldDefinitionDialog> {
  final _labelCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();
  CustomFieldType _type = CustomFieldType.text;
  bool _isRequired = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeLabels = {
      CustomFieldType.text: 'Text',
      CustomFieldType.number: 'Number',
      CustomFieldType.date: 'Date',
      CustomFieldType.dropdown: 'Dropdown',
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadii.r12,
                    ),
                    child: Icon(
                      Icons.add_box_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Custom Field',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          'Define a custom data field for students.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _labelCtrl,
                    label: 'Field Label',
                    hintText: 'e.g. Guardian CNIC',
                    prefixIcon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<CustomFieldType>(
                    label: 'Field Type',
                    items: CustomFieldType.values,
                    value: _type,
                    itemLabel: (t) => typeLabels[t] ?? t.name,
                    prefixIcon: Icons.category_outlined,
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  if (_type == CustomFieldType.dropdown) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _optionsCtrl,
                      label: 'Options (comma separated)',
                      hintText: 'A+, B+, O-',
                      prefixIcon: Icons.list_rounded,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Required toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: AppRadii.r12,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isRequired
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _isRequired ? cs.primary : cs.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Required Field',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _isRequired,
                            onChanged: (v) => setState(() => _isRequired = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // ── Footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppPrimaryButton(
                    label: 'Create Field',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      if (_labelCtrl.text.trim().isEmpty) return;
                      final key = _labelCtrl.text
                          .trim()
                          .toLowerCase()
                          .replaceAll(' ', '_')
                          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                      final options = _optionsCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      widget.onSave(
                        StudentCustomField(
                          id: '',
                          key: key,
                          label: _labelCtrl.text.trim(),
                          type: _type,
                          isRequired: _isRequired,
                          options: options,
                          createdAt: DateTime.now(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
