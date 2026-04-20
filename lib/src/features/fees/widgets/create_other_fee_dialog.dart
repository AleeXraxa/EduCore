import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';

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
  List<FeePlan> _feePlans = [];
  Map<String, String> _students = {}; // studentId -> name

  FeePlan? _selectedPlan;
  bool _isOverrideEnabled = false;
  final _reasonCtrl = TextEditingController();
  bool _canOverride = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchClasses();
    _fetchFeePlans();
  }

  void _checkPermissions() {
    _canOverride = AppServices.instance.featureAccessService!.canAccess('fee_override');
  }

  Future<void> _fetchClasses() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(
      academyId,
    );
    if (mounted) setState(() => _classes = classes);
  }

  Future<void> _fetchFeePlans() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final plans = await AppServices.instance.feePlanService!.getFeePlans(academyId);
    if (mounted) setState(() => _feePlans = plans);
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

            AppDropdown<FeePlan>(
              label: 'Select Fee Plan',
              items: _feePlans,
              value: _selectedPlan,
              itemLabel: (p) => '${p.name} (Rs. ${p.monthlyFee})',
              onChanged: (v) {
                setState(() {
                  _selectedPlan = v;
                  if (!_isOverrideEnabled) {
                    _amountCtrl.text = v?.monthlyFee.toStringAsFixed(0) ?? '';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _titleCtrl,
              label: 'Fee Title',
              hintText: 'e.g. Exam Fee, Sports Fee',
            ),

            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _amountCtrl,
                    label: 'Amount (Rs.)',
                    enabled: _isOverrideEnabled && _canOverride,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                    helperText: _isOverrideEnabled ? 'Manually Overridden' : 'Controlled by Fee Plan',
                  ),
                ),
                if (_canOverride) ...[
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text('Override', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Switch.adaptive(
                        value: _isOverrideEnabled,
                        onChanged: (v) {
                          setState(() {
                            _isOverrideEnabled = v;
                            if (!v && _selectedPlan != null) {
                              _amountCtrl.text = _selectedPlan!.monthlyFee.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),

            if (_isOverrideEnabled) ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _reasonCtrl,
                label: 'Reason for Override',
                hintText: 'Required for auditing...',
                prefixIcon: Icons.edit_note_rounded,
              ),
            ],

            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Create Fee Record',
              icon: Icons.add_circle_outline_rounded,
              busy: _isLoading,
              onPressed: () async {
                if (_selectedClassId == null ||
                    _selectedStudentId == null ||
                    _selectedPlan == null ||
                    _titleCtrl.text.isEmpty ||
                    _amountCtrl.text.isEmpty) {
                  return;
                }

                if (_isOverrideEnabled && _reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason for override')),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                final originalAmount = _selectedPlan!.monthlyFee;
                final amount = double.tryParse(_amountCtrl.text) ?? originalAmount;
                final user = AppServices.instance.authService!.session!;

                final fee = Fee(
                  id: '',
                  academyId: user.academyId,
                  studentId: _selectedStudentId!,
                  classId: _selectedClassId!,
                  feePlanId: _selectedPlan!.id,
                  type: FeeType.other,
                  title: _titleCtrl.text.trim(),
                  originalAmount: originalAmount,
                  finalAmount: amount,
                  isOverridden: _isOverridden(amount, originalAmount),
                  overrideReason: _isOverrideEnabled ? _reasonCtrl.text.trim() : null,
                  overriddenBy: _isOverrideEnabled ? user.user.uid : null,
                  overriddenAt: _isOverrideEnabled ? DateTime.now() : null,
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

  bool _isOverridden(double finalAmount, double originalAmount) {
    return _isOverrideEnabled && (finalAmount != originalAmount);
  }
}
