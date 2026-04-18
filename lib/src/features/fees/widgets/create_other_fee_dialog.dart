import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/fees/models/fee.dart';

class CreateOtherFeeDialog extends StatefulWidget {
  final Function(Fee) onCreate;

  const CreateOtherFeeDialog({super.key, required this.onCreate});

  @override
  State<CreateOtherFeeDialog> createState() => _CreateOtherFeeDialogState();
}

class _CreateOtherFeeDialogState extends State<CreateOtherFeeDialog> {
  String? _selectedClassId;
  String? _selectedStudentId;
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  List<InstituteClass> _classes = [];
  Map<String, String> _students = {}; // studentId -> name

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(
      academyId,
    );
    if (mounted) setState(() => _classes = classes);
  }

  Future<void> _fetchStudentsForClass(String classId) async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final snapshot = await AppServices.instance.studentService!
        .getStudentsBatch(
          academyId: academyId,
          classIdFilter: classId,
          limit: 100, // Load enough for a dropdown
        );

    if (mounted) {
      setState(() {
        _students = {
          for (var doc in snapshot.docs) doc.id: doc.data()['name'] as String,
        };
        _selectedStudentId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Manual Fee',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),

            AppDropdown<String>(
              label: 'Select Class',
              items: _classes.map((c) => c.id).toList(),
              value: _selectedClassId,
              itemLabel: (id) =>
                  _classes.firstWhere((c) => c.id == id).displayName,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedClassId = v);
                _fetchStudentsForClass(v);
              },
            ),
            const SizedBox(height: 16),

            if (_selectedClassId != null)
              AppDropdown<String>(
                label: 'Select Student',
                items: _students.keys.toList(),
                value: _selectedStudentId,
                itemLabel: (id) => _students[id] ?? id,
                onChanged: (v) => setState(() => _selectedStudentId = v),
              ),

            const SizedBox(height: 16),
            AppTextField(
              controller: _titleCtrl,
              label: 'Fee Title',
              hintText: 'e.g. Exam Fee, Sports Fee',
            ),

            const SizedBox(height: 16),
            AppTextField(
              controller: _amountCtrl,
              label: 'Amount (Rs.)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee_rounded,
            ),

            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Create Fee Record',
              icon: Icons.add_circle_outline_rounded,
              busy: _isLoading,
              onPressed: () async {
                if (_selectedClassId == null ||
                    _selectedStudentId == null ||
                    _titleCtrl.text.isEmpty ||
                    _amountCtrl.text.isEmpty) {
                  return;
                }

                setState(() => _isLoading = true);

                final amount = double.tryParse(_amountCtrl.text) ?? 0;

                final fee = Fee(
                  id: '',
                  academyId: '', // Filled by service
                  studentId: _selectedStudentId!,
                  classId: _selectedClassId!,
                  type: FeeType.other,
                  title: _titleCtrl.text.trim(),
                  amount: amount,
                  status: FeeStatus.pending,
                  paidAmount: 0,
                  studentName: _students[_selectedStudentId!] ?? '',
                  className: _classes
                      .firstWhere((c) => c.id == _selectedClassId)
                      .displayName,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await widget.onCreate(fee);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
