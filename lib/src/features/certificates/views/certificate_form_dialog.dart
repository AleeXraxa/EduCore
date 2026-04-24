import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/certificates/models/certificate.dart';
import 'package:educore/src/features/certificates/models/certificate_template.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CertificateFormDialog extends StatefulWidget {
  const CertificateFormDialog({super.key, this.certificate});
  final Certificate? certificate;

  @override
  State<CertificateFormDialog> createState() => _CertificateFormDialogState();
}

class _CertificateFormDialogState extends State<CertificateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  Student? _selectedStudent;
  CertificateType _type = CertificateType.achievement;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _signatoryController;
  late final TextEditingController _remarksController;
  DateTime _issueDate = DateTime.now();
  DateTime? _validUntil;
  
  bool _loadingStudents = true;
  List<Student> _students = [];
  bool _loadingTemplates = true;
  List<CertificateTemplate> _templates = [];
  CertificateTemplate? _selectedTemplate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.certificate?.title ?? '');
    _bodyController = TextEditingController(text: widget.certificate?.body ?? _getDefaultBody(_type));
    _signatoryController = TextEditingController(text: widget.certificate?.authorizedSignatory ?? '');
    _remarksController = TextEditingController(text: widget.certificate?.remarks ?? '');
    
    if (widget.certificate != null) {
      _type = widget.certificate!.type;
      _issueDate = widget.certificate!.issueDate;
      _validUntil = widget.certificate!.validUntil;
    }

    _loadStudents();
    _loadTemplates();
  }

  String _getDefaultBody(CertificateType type) {
    switch (type) {
      case CertificateType.character:
        return 'This is to certify that {student_name}, son/daughter of [Guardian Name], was a student of this institute in class {class_name}. During their stay, their conduct and character were found to be excellent.';
      case CertificateType.completion:
        return 'This is to certify that {student_name} has successfully completed the prescribed course of study in class {class_name} during the academic session [Session].';
      case CertificateType.achievement:
        return 'This certificate is proudly awarded to {student_name} for outstanding achievement and excellence in [Subject/Field].';
      case CertificateType.participation:
        return 'This is to certify that {student_name} actively participated in [Event Name] held on [Date].';
      case CertificateType.bonafide:
        return 'This is to certify that {student_name}, Roll No. {roll_no}, is a bonafide student of class {class_name} in this institute.';
      case CertificateType.leaving:
        return 'This is to certify that {student_name} was a student of this institute from [Start Date] to [End Date]. They are leaving the institute due to [Reason].';
      case CertificateType.custom:
        return '';
    }
  }

  Future<void> _loadStudents() async {
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId == null) return;

    final students = await AppServices.instance.studentService?.getStudents(academyId) ?? [];
    if (mounted) {
      setState(() {
        _students = students;
        _loadingStudents = false;
        
        if (widget.certificate != null) {
          _selectedStudent = _students.cast<Student?>().firstWhere(
            (s) => s?.id == widget.certificate!.studentId,
            orElse: () => null,
          );
        }
      });
    }
  }

  Future<void> _loadTemplates() async {
    final academyId = AppServices.instance.authService?.currentAcademyId;
    if (academyId == null) return;

    final templates = await AppServices.instance.certificateTemplateService?.getTemplates(academyId) ?? [];
    if (mounted) {
      setState(() {
        _templates = templates;
        _loadingTemplates = false;
        
        if (widget.certificate != null) {
          _selectedTemplate = _templates.cast<CertificateTemplate?>().firstWhere(
            (t) => t?.id == widget.certificate!.templateId,
            orElse: () => null,
          );
        } else if (_templates.isNotEmpty) {
          _selectedTemplate = _templates.cast<CertificateTemplate?>().firstWhere(
            (t) => t?.isDefault ?? false,
            orElse: () => _templates.first,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _signatoryController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || (_selectedStudent == null && widget.certificate == null)) {
      if (_selectedStudent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a student')),
        );
      }
      return;
    }

    final academyId = AppServices.instance.authService?.currentAcademyId;
    final userId = AppServices.instance.authService?.currentUser?.uid;
    if (academyId == null || userId == null) return;

    final confirmed = widget.certificate == null 
        ? await AppDialogs.showAddConfirmation(context, title: 'Generate Certificate')
        : await AppDialogs.showEditConfirmation(context, title: 'Update Certificate');
    
    if (!mounted || confirmed != true) return;

    setState(() => _saving = true);
    if (!mounted) return;
    AppDialogs.showLoading(context, message: 'Saving certificate...');

    try {
      final cert = Certificate(
        id: widget.certificate?.id ?? '',
        studentId: _selectedStudent?.id ?? widget.certificate!.studentId,
        studentName: _selectedStudent?.name ?? widget.certificate!.studentName,
        studentRollNo: _selectedStudent?.rollNo ?? widget.certificate!.studentRollNo,
        className: _selectedStudent?.className ?? widget.certificate!.className,
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        issueDate: _issueDate,
        validUntil: _validUntil,
        authorizedSignatory: _signatoryController.text.trim(),
        remarks: _remarksController.text.trim(),
        createdAt: widget.certificate?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.certificate?.createdBy ?? userId,
        academyId: academyId,
        academyName: AppServices.instance.authService?.currentAcademyName ?? 'Unknown Academy',
        templateId: _selectedTemplate?.id,
        templateBackgroundUrl: _selectedTemplate?.backgroundUrl,
      );

      bool success = false;
      if (widget.certificate == null) {
        final id = await AppServices.instance.certificateService?.createCertificate(
          academyId: academyId,
          certificate: cert,
        );
        success = id != null;
      } else {
        await AppServices.instance.certificateService?.updateCertificate(
          academyId: academyId,
          certificate: cert,
        );
        success = true;
      }

      if (mounted) {
        AppDialogs.hideLoading(context);
        if (success) {
          Navigator.of(context).pop();
          AppDialogs.showSuccess(
            context,
            title: 'Success',
            message: 'Certificate has been ${widget.certificate == null ? 'generated' : 'updated'}.',
          );
        } else {
          AppDialogs.showError(context, title: 'Error', message: 'Failed to save certificate.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.hideLoading(context);
        AppDialogs.showError(context, title: 'Error', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.certificate != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_document : Icons.workspace_premium_rounded,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Certificate' : 'Generate Certificate',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          isEditing ? 'Update existing certificate details' : 'Issue a new certificate to a student',
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

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('RECIPIENT & TYPE'),
                      const SizedBox(height: 16),
                      _loadingStudents
                          ? const Center(child: LinearProgressIndicator())
                          : AppDropdown<Student>(
                              label: 'Select Student',
                              hintText: 'Search by name...',
                              items: _students,
                              value: _selectedStudent,
                              onChanged: (v) => setState(() => _selectedStudent = v),
                              itemLabel: (s) => '${s.name} (${s.className})',
                              prefixIcon: Icons.person_search_rounded,
                            ),

                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _loadingTemplates
                                ? const Center(child: LinearProgressIndicator())
                                : AppDropdown<CertificateTemplate>(
                                    label: 'Certificate Template',
                                    hintText: 'Select a layout...',
                                    items: _templates,
                                    value: _selectedTemplate,
                                    onChanged: (v) => setState(() => _selectedTemplate = v),
                                    itemLabel: (t) => t.name,
                                    prefixIcon: Icons.layers_rounded,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: AppDropdown<CertificateType>(
                              label: 'Type',
                              items: CertificateType.values,
                              value: _type,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _type = v;
                                    if (_bodyController.text == _getDefaultBody(_type) || _bodyController.text.isEmpty) {
                                      _bodyController.text = _getDefaultBody(_type);
                                    }
                                  });
                                }
                              },
                              itemLabel: (t) => t.label,
                              prefixIcon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      _sectionTitle('CERTIFICATE CONTENT'),
                      const SizedBox(height: 16),
                      
                      AppTextField(
                        controller: _titleController,
                        label: 'Certificate Title',
                        hintText: 'e.g., CHARACTER CERTIFICATE',
                        prefixIcon: Icons.title_rounded,
                        validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                      ),
                      
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _bodyController,
                        label: 'Certificate Body',
                        hintText: 'Use {student_name}, {class_name}, {roll_no} as placeholders...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                        validator: (v) => v == null || v.isEmpty ? 'Body is required' : null,
                      ),
                      
                      const SizedBox(height: 24),
                      _sectionTitle('DATES & AUTHORIZATION'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Issue Date',
                              value: _issueDate,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _issueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) setState(() => _issueDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              label: 'Valid Until (Optional)',
                              value: _validUntil,
                              isOptional: true,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _validUntil ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                setState(() => _validUntil = d);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _signatoryController,
                        label: 'Authorized Signatory',
                        hintText: 'e.g., Principal, Director',
                        prefixIcon: Icons.draw_rounded,
                        validator: (v) => v == null || v.isEmpty ? 'Signatory is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(32),
              child: AppPrimaryButton(
                onPressed: _saving ? null : _save,
                label: isEditing ? 'Update Certificate' : 'Generate Certificate',
                icon: isEditing ? Icons.save_rounded : Icons.auto_awesome_rounded,
                busy: _saving,
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
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: cs.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool isOptional = false,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary.withOpacity(0.7)),
                const SizedBox(width: 12),
                Text(
                  value == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(value),
                  style: TextStyle(
                    color: value == null ? cs.onSurfaceVariant : cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

