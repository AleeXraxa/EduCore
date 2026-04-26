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
  
  bool _isDiscountEnabled = false;
  DiscountType _discountType = DiscountType.flat;
  final _discountValueCtrl = TextEditingController(text: '0');

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
        child: SingleChildScrollView(
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

              AppDropdown<FeePlan?>(
                label: 'Select Fee Plan (Optional)',
                items: [null, ..._feePlans],
                value: _selectedPlan,
                itemLabel: (p) => p == null ? 'Custom / No Plan' : '${p.name} (PKR ${p.monthlyFee})',
                onChanged: (v) {
                  setState(() {
                    _selectedPlan = v;
                    if (v != null) {
                      _amountCtrl.text = v.monthlyFee.toStringAsFixed(0);
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
              
              AppTextField(
                controller: _amountCtrl,
                label: 'Amount (PKR)',
                enabled: true,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
                helperText: 'Enter the final amount to be charged',
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: _reasonCtrl,
                label: 'Remarks / Reason',
                hintText: 'Note for this manual fee...',
                prefixIcon: Icons.edit_note_rounded,
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Discount Section
              GestureDetector(
                onTap: () => setState(() => _isDiscountEnabled = !_isDiscountEnabled),
                child: Row(
                  children: [
                    Icon(
                      _isDiscountEnabled ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: _isDiscountEnabled ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    const Text('Apply Discount / Scholarship', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              if (_isDiscountEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppDropdown<DiscountType>(
                        label: 'Type',
                        items: const [DiscountType.flat, DiscountType.percent],
                        value: _discountType,
                        itemLabel: (t) => t == DiscountType.flat ? 'Flat (PKR)' : 'Percent (%)',
                        onChanged: (v) => setState(() => _discountType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        controller: _discountValueCtrl,
                        label: 'Value',
                        keyboardType: TextInputType.number,
                        prefixIcon: _discountType == DiscountType.flat ? Icons.money_off_rounded : Icons.percent_rounded,
                      ),
                    ),
                  ],
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
                      _titleCtrl.text.isEmpty ||
                      _amountCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }


                  setState(() => _isLoading = true);

                   final originalAmount = _selectedPlan?.monthlyFee ?? (double.tryParse(_amountCtrl.text) ?? 0.0);
                  double finalAmount = double.tryParse(_amountCtrl.text) ?? originalAmount;
                  final user = AppServices.instance.authService!.session!;

                  DiscountType dType = DiscountType.none;
                  double dValue = 0.0;
                  double dAmount = 0.0;

                  if (_isDiscountEnabled) {
                    dType = _discountType;
                    dValue = double.tryParse(_discountValueCtrl.text) ?? 0.0;
                    final result = Fee.calculateDiscount(finalAmount, dType, dValue);
                    dAmount = result.$1;
                    finalAmount = result.$2;
                  }

                  final fee = Fee(
                    id: '',
                    academyId: user.academyId,
                    studentId: _selectedStudentId!,
                    classId: _selectedClassId!,
                    feePlanId: _selectedPlan?.id ?? 'manual',
                    type: FeeType.other,
                    title: _titleCtrl.text.trim(),
                    originalAmount: originalAmount,
                    finalAmount: finalAmount,
                    discountType: dType,
                    discountValue: dValue,
                    discountAmount: dAmount,
                    isOverridden: _selectedPlan != null && finalAmount != originalAmount,
                    overrideReason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
                    overriddenBy: _selectedPlan != null && finalAmount != originalAmount ? user.user.uid : null,
                    overriddenAt: _selectedPlan != null && finalAmount != originalAmount ? DateTime.now() : null,
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
      ),
    );
  }

  bool _isOverridden(double finalAmount, double originalAmount) {
    return _isOverrideEnabled && (finalAmount != originalAmount);
  }
}
