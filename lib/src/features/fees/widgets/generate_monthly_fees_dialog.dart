import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_form_wizard.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
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
  int _currentStep = 0;
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedClassId;
  DateTime _selectedMonth = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController(text: 'Monthly Fee');
  final _reasonCtrl = TextEditingController();
  List<InstituteClass> _classes = [];
  bool _isLoading = false;
  bool _canOverride = false;
  bool _isOverrideEnabled = false;
  double _planAmount = 0;
  String? _blockMessage;

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
      // Plan fetching logic remains internal
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedClassId == null) return;
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_selectedClassId == null) return;

    if (_isOverrideEnabled && _reasonCtrl.text.trim().isEmpty) {
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
        if (error != null && count < 0) {
          _blockMessage = error;
        }
      });
      if (count >= 0) Navigator.pop(context, count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(cs),
            
            AppFormWizard(
              currentStep: _currentStep,
              steps: const ['Selection', 'Configuration'],
              onStepTapped: (idx) {
                if (idx < _currentStep) {
                  setState(() => _currentStep = idx);
                  _pageController.animateToPage(idx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
                }
              },
            ),
            
            const Divider(height: 1),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(cs),
                    _buildStep2(cs),
                  ],
                ),
              ),
            ),
            
            const Divider(height: 1),
            
            _buildFooter(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, color: cs.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Fee Engine',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('Generate invoices for multiple students', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  Widget _buildStep1(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            label: 'Target Class',
            prefixIcon: Icons.school_rounded,
            items: _classes.map((c) => c.id).toList(),
            value: _selectedClassId,
            itemLabel: (id) => _classes.firstWhere((c) => c.id == id).displayName,
            onChanged: _onClassChanged,
          ),
          const SizedBox(height: 32),
          const Text('Fee Month', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                helpText: 'SELECT MONTH',
              );
              if (picked != null) setState(() => _selectedMonth = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: AppRadii.r16,
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: cs.primary),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormInputField(
            controller: _titleCtrl,
            label: 'Fee Description',
            hint: 'e.g. Monthly Tuition Fee',
            icon: Icons.title_rounded,
            validator: (v) => v!.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppFormInputField(
                  controller: _amountCtrl,
                  label: 'Amount (PKR)',
                  hint: 'Enter amount',
                  icon: Icons.payments_rounded,
                  readOnly: !_isOverrideEnabled || !_canOverride,
                  keyboardType: TextInputType.number,
                ),
              ),
              if (_canOverride) ...[
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Override', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    Switch.adaptive(
                      value: _isOverrideEnabled,
                      onChanged: (v) {
                        setState(() {
                          _isOverrideEnabled = v;
                          if (!v) _amountCtrl.text = _planAmount.toStringAsFixed(0);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (_isOverrideEnabled) ...[
            const SizedBox(height: 24),
            AppFormInputField(
              controller: _reasonCtrl,
              label: 'Override Rationale',
              hint: 'Required for auditing',
              icon: Icons.edit_note_rounded,
              validator: (v) => v!.isEmpty ? 'Reason required for override' : null,
            ),
          ],
          if (_blockMessage != null) ...[
            const SizedBox(height: 24),
            _LockStatusBanner(message: _blockMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep = 0);
                  _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppPrimaryButton(
              onPressed: _blockMessage != null ? null : _nextStep,
              busy: _isLoading,
              label: _currentStep == 0 ? 'Review Configuration' : 'Run Generation Engine',
            ),
          ),
        ],
      ),
    );
  }
}

class _LockStatusBanner extends StatelessWidget {
  const _LockStatusBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isCompleted = message.toLowerCase().contains('already been generated');
    final color = isCompleted ? Colors.orange : Colors.blue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(isCompleted ? Icons.lock_rounded : Icons.sync_rounded, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'BLOCKED' : 'SYSTEM BUSY',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                Text(message, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
