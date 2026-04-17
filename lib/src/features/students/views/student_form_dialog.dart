import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentFormDialog extends StatefulWidget {
  const StudentFormDialog({
    super.key,
    this.student,
    required this.controller,
  });

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
  late String _selectedClass;
  late String _status;
  bool _isLoading = false;

  final List<String> _classes = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'];
  final Map<String, TextEditingController> _dynamicControllers = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student?.name ?? '');
    _fatherNameCtrl = TextEditingController(text: widget.student?.fatherName ?? '');
    _phoneCtrl = TextEditingController(text: widget.student?.phone ?? '');
    _selectedClass = widget.student?.className ?? _classes.first;
    _status = widget.student?.status ?? 'active';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.resetDynamicForm(widget.student?.customFields);
    });
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newStudent = Student(
      id: widget.student?.id ?? '',
      name: _nameCtrl.text.trim(),
      fatherName: _fatherNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      className: _selectedClass,
      admissionDate: widget.student?.admissionDate ?? DateTime.now(),
      status: _status,
      createdAt: widget.student?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      customFields: Map<String, dynamic>.from(widget.controller.dynamicFormState),
    );

    bool success;
    if (widget.student == null) {
      success = await widget.controller.addStudent(newStudent);
    } else {
      success = await widget.controller.updateStudent(newStudent);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student ${widget.student == null ? 'added' : 'updated'} successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save student. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
                      isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          isEditing ? 'Update student details' : 'Add a new student to system',
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
                        validator: (v) => v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _fatherNameCtrl,
                        label: 'Father\'s Name',
                        hint: 'Enter guardian name',
                        icon: Icons.family_restroom_outlined,
                        validator: (v) => v!.isEmpty ? 'Father name is required' : null,
                      ),
                      
                      const SizedBox(height: 32),
                      _sectionTitle('ENROLLMENT DETAILS'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedClass,
                              label: 'Class',
                              icon: Icons.school_outlined,
                              items: _classes,
                              onChanged: (v) => setState(() => _selectedClass = v!),
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                value: _status,
                                label: 'Status',
                                icon: Icons.info_outline_rounded,
                                items: const ['active', 'inactive'],
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _phoneCtrl,
                        label: 'Contact Number',
                        hint: '03XX XXXXXXX',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
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
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEditing ? 'Update Student' : 'Enroll Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: cs.onSurfaceVariant),
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
        ...definitions.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildDynamicField(field),
            )),
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
          () => TextEditingController(text: value?.toString() ?? '')
        );
        
        return _buildField(
          controller: ctrl,
          label: field.label,
          hint: 'Enter ${field.label.toLowerCase()}',
          icon: field.type == CustomFieldType.number ? Icons.numbers_rounded : Icons.text_fields_rounded,
          keyboardType: field.type == CustomFieldType.number ? TextInputType.number : TextInputType.text,
          validator: field.isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
          onChanged: (v) => widget.controller.updateDynamicField(field.key, v),
        );
      case CustomFieldType.date:
        return _buildDateField(field);
      case CustomFieldType.dropdown:
        return _buildDropdown(
          value: value ?? (field.options.isNotEmpty ? field.options.first : ''),
          label: field.label,
          icon: Icons.list_rounded,
          items: field.options,
          onChanged: (v) => widget.controller.updateDynamicField(field.key, v),
        );
    }
  }

  Widget _buildDateField(StudentCustomField field) {
    final value = widget.controller.dynamicFormState[field.key];
    final dateStr = value is DateTime ? DateFormat('yyyy-MM-dd').format(value) : (value?.toString() ?? 'Select Date');
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: cs.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
                Text(dateStr, style: TextStyle(color: value == null ? cs.onSurfaceVariant : cs.onSurface)),
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
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
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e.substring(0, 1).toUpperCase() + e.substring(1)),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AddCustomFieldDefinitionDialog extends StatefulWidget {
  final Function(StudentCustomField) onSave;
  const _AddCustomFieldDefinitionDialog({required this.onSave});

  @override
  State<_AddCustomFieldDefinitionDialog> createState() => __AddCustomFieldDefinitionDialogState();
}

class __AddCustomFieldDefinitionDialogState extends State<_AddCustomFieldDefinitionDialog> {
  final _labelCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();
  CustomFieldType _type = CustomFieldType.text;
  bool _isRequired = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Field', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Field Label',
                hintText: 'e.g. Guardian CNIC',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomFieldType>(
              value: _type,
              items: CustomFieldType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(
                labelText: 'Field Type',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            if (_type == CustomFieldType.dropdown) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _optionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Options (comma separated)',
                  hintText: 'A+, B+, O-',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Required Field', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              value: _isRequired,
              onChanged: (v) => setState(() => _isRequired = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_labelCtrl.text.isEmpty) return;
            final key = _labelCtrl.text.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
            final options = _optionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            
            widget.onSave(StudentCustomField(
              id: '',
              key: key,
              label: _labelCtrl.text.trim(),
              type: _type,
              isRequired: _isRequired,
              options: options,
              createdAt: DateTime.now(),
            ));
          },
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Create Field'),
        ),
      ],
    );
  }
}
