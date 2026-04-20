import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:intl/intl.dart';

class GenerateMonthlyFeesDialog extends StatefulWidget {
  final Future<(int, String?)> Function({
    required String classId,
    required String month,
    double? amount,
    String? overrideReason,
    required String title,
    DateTime? dueDate,
  }) onGenerate;

  const GenerateMonthlyFeesDialog({super.key, required this.onGenerate});

  @override
  State<GenerateMonthlyFeesDialog> createState() => _GenerateMonthlyFeesDialogState();
}

class _GenerateMonthlyFeesDialogState extends State<GenerateMonthlyFeesDialog> {
  String? _selectedClassId;
  DateTime _selectedMonth = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController(text: 'Monthly Fee');
  final _reasonCtrl = TextEditingController();
  List<InstituteClass> _classes = [];
  bool _isLoading = false;
  bool _isFetchingPlan = false;
  bool _canOverride = false;
  bool _isOverrideEnabled = false;
  double _planAmount = 0;
  String? _blockMessage; // Set when generation is blocked by a lock

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchClasses();
  }

  void _checkPermissions() {
    _canOverride = AppServices.instance.featureAccessService!.canAccess('fee_override');
  }

  Future<void> _fetchClasses() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(academyId);
    setState(() => _classes = classes);
  }

  void _onClassChanged(String? id) {
    if (id == null) return;
    setState(() {
      _selectedClassId = id;
      _amountCtrl.clear();
      final cls = _classes.firstWhere((c) => c.id == id);
      
      if (cls.feePlanId != null) {
        _fetchPlanAmount(id, cls.feePlanId!);
      }
    });
  }

  Future<void> _fetchPlanAmount(String classId, String planId) async {
    setState(() => _isFetchingPlan = true);
    try {
      final academyId = AppServices.instance.authService!.session!.academyId;
      final plan = await AppServices.instance.feePlanService!.getFeePlan(academyId, planId);
      if (plan != null && mounted && _selectedClassId == classId) {
        setState(() {
          _planAmount = plan.monthlyFee;
          if (!_isOverrideEnabled) {
            _amountCtrl.text = _planAmount.toStringAsFixed(0);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isFetchingPlan = false);
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
              'Batch Fee Generation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            
            AppDropdown<String>(
              label: 'Select Class',
              items: _classes.map((c) => c.id).toList(),
              value: _selectedClassId,
              itemLabel: (id) => _classes.firstWhere((c) => c.id == id).displayName,
              onChanged: _onClassChanged,
            ),
            
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                // Simplified month picker
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  helpText: 'SELECT MONTH',
                );
                if (picked != null) setState(() => _selectedMonth = picked);
              },
              child: AppTextField(
                controller: TextEditingController(text: DateFormat('MMMM yyyy').format(_selectedMonth)),
                label: 'Fee Month',
                enabled: false,
                prefixIcon: Icons.calendar_month_rounded,
              ),
            ),
            
            const SizedBox(height: 16),
            AppTextField(
              controller: _titleCtrl,
              label: 'Fee Title',
              hintText: 'e.g. Monthly Tuition Fee',
            ),
            
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
                    suffixIcon: _isFetchingPlan 
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
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
                            if (!v) {
                              _amountCtrl.text = _planAmount.toStringAsFixed(0);
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

            // Lock status banner
            if (_blockMessage != null) ...[
              _LockStatusBanner(message: _blockMessage!),
              const SizedBox(height: 12),
            ],

            AppPrimaryButton(
              label: 'Generate Bulk Fees',
              icon: Icons.flash_on_rounded,
              busy: _isLoading,
              onPressed: _blockMessage != null
                  ? null // Disabled when a lock is blocking
                  : () async {
                      if (_selectedClassId == null) return;

                      if (_isOverrideEnabled && _reasonCtrl.text.trim().isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide a reason for override')),
                        );
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                        _blockMessage = null;
                      });

                      final (count, error) = await widget.onGenerate(
                        classId: _selectedClassId!,
                        month: DateFormat('yyyy-MM').format(_selectedMonth),
                        amount: _isOverrideEnabled ? double.tryParse(_amountCtrl.text) : null,
                        overrideReason: _isOverrideEnabled ? _reasonCtrl.text.trim() : null,
                        title: _titleCtrl.text,
                      );

                      if (context.mounted) {
                        setState(() {
                          _isLoading = false;
                          // Surface lock errors inline; other errors let the
                          // outer toast handle them.
                          if (error != null && count < 0) {
                            _blockMessage = error;
                          }
                        });
                        if (count >= 0) Navigator.pop(context);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline banner displayed inside the dialog when generation is blocked
/// by an existing lock (processing or already completed).
class _LockStatusBanner extends StatelessWidget {
  const _LockStatusBanner({required this.message});
  final String message;

  bool get _isCompleted => message.toLowerCase().contains('already been generated');

  @override
  Widget build(BuildContext context) {
    final isCompleted = _isCompleted;
    final color = isCompleted ? Colors.orange : Colors.blue;
    final icon = isCompleted ? Icons.lock_rounded : Icons.sync_rounded;
    final label = isCompleted ? 'ALREADY GENERATED' : 'IN PROGRESS';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
