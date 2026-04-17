import 'package:educore/src/features/students/controllers/student_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student?.name ?? '');
    _fatherNameCtrl = TextEditingController(text: widget.student?.fatherName ?? '');
    _phoneCtrl = TextEditingController(text: widget.student?.phone ?? '');
    _selectedClass = widget.student?.className ?? _classes.first;
    _status = widget.student?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _phoneCtrl.dispose();
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
    );

    bool success;
    if (widget.student == null) {
      success = await widget.controller.addStudent(newStudent);
    } else {
      success = await widget.controller.updateStudent(newStudent);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student ${widget.student == null ? 'added' : 'updated'} successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save student. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.student != null;

    return AlertDialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fatherNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Father\'s Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (03xxxxxxxx)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^03\d{9}$').hasMatch(val.trim())) {
                      return 'Enter a valid 11-digit phone number (e.g. 03001234567)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClass = val);
                  },
                ),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
