import 'package:educore/src/core/ui/widgets/app_form_wizard.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/features/fees/controllers/fee_plans_controller.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:flutter/material.dart';

class CreateEditFeePlanDialog extends StatefulWidget {
  const CreateEditFeePlanDialog({
    super.key,
    required this.controller,
    this.plan,
  });

  final FeePlansController controller;
  final FeePlan? plan;

  static Future<void> show(
    BuildContext context, {
    required FeePlansController controller,
    FeePlan? plan,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CreateEditFeePlanDialog(
        controller: controller,
        plan: plan,
      ),
    );
  }

  @override
  State<CreateEditFeePlanDialog> createState() => _CreateEditFeePlanDialogState();
}

class _CreateEditFeePlanDialogState extends State<CreateEditFeePlanDialog> {
  int _currentStep = 0;
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _admissionController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _totalFeeController;
  late final TextEditingController _durationController;
  late final TextEditingController _installmentsController;
  late final TextEditingController _lateFeeController;
  
  String _scope = 'class';
  FeePlanType _planType = FeePlanType.monthly;
  bool _allowPartial = true;
  bool _allowInstallments = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name);
    _descController = TextEditingController(text: widget.plan?.description);
    _admissionController = TextEditingController(text: widget.plan?.admissionFee.toStringAsFixed(0) ?? '0');
    _monthlyController = TextEditingController(text: widget.plan?.monthlyFee.toStringAsFixed(0) ?? '0');
    _dueDayController = TextEditingController(text: widget.plan?.monthlyDueDay.toString() ?? '5');
    _totalFeeController = TextEditingController(text: widget.plan?.totalCourseFee.toStringAsFixed(0) ?? '0');
    _durationController = TextEditingController(text: widget.plan?.durationMonths?.toString() ?? '1');
    _installmentsController = TextEditingController(text: widget.plan?.installmentCount?.toString() ?? '1');
    _lateFeeController = TextEditingController(text: widget.plan?.lateFeePerDay?.toStringAsFixed(0));
    
    if (widget.plan != null) {
      _scope = widget.plan!.scope;
      _planType = widget.plan!.planType;
      _allowPartial = widget.plan!.allowPartialPayment;
      _allowInstallments = widget.plan!.allowInstallments;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _admissionController.dispose();
    _monthlyController.dispose();
    _dueDayController.dispose();
    _totalFeeController.dispose();
    _durationController.dispose();
    _installmentsController.dispose();
    _lateFeeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 2) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep++);
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
      }
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
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
          children: [
            _buildHeader(cs),
            
            AppFormWizard(
              currentStep: _currentStep,
              steps: const ['Definition', 'Financials', 'Policies'],
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
                    _buildStep3(cs),
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
            child: Icon(Icons.receipt_long_rounded, color: cs.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan == null ? 'New Fee Plan' : 'Edit Fee Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('Configure pricing and billing logic', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
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
          _buildSectionLabel('BILLING ARCHITECTURE'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildModelOption(FeePlanType.monthly, 'Monthly', Icons.calendar_month_rounded, cs),
                _buildModelOption(FeePlanType.package, 'Package', Icons.inventory_2_rounded, cs),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppFormInputField(
            controller: _nameController,
            label: 'Plan Name',
            hint: 'e.g. Standard Grade 10 Plan',
            icon: Icons.label_important_rounded,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          AppDropdown<String>(
            label: 'Plan Scope',
            prefixIcon: Icons.category_rounded,
            items: const ['class', 'custom'],
            value: _scope,
            onChanged: (v) => setState(() => _scope = v!),
            itemLabel: (v) => v.toUpperCase(),
          ),
          const SizedBox(height: 24),
          AppFormInputField(
            controller: _descController,
            label: 'Internal Description',
            hint: 'Briefly describe this plan...',
            icon: Icons.notes_rounded,
            maxLines: 2,
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
          _buildSectionLabel('CORE FEES'),
          const SizedBox(height: 16),
          AppFormInputField(
            controller: _admissionController,
            label: 'Admission Fee',
            hint: '0',
            icon: Icons.login_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          AppFormInputField(
            controller: _planType == FeePlanType.monthly ? _monthlyController : _totalFeeController,
            label: _planType == FeePlanType.monthly ? 'Monthly Subscription' : 'Full Package Price',
            hint: '0',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 32),
          _buildSectionLabel('TIME CONSTRAINTS'),
          const SizedBox(height: 16),
          if (_planType == FeePlanType.monthly)
            AppFormInputField(
              controller: _dueDayController,
              label: 'Monthly Due Day',
              hint: '5',
              icon: Icons.event_note_rounded,
              keyboardType: TextInputType.number,
              validator: (v) {
                final d = int.tryParse(v ?? '');
                if (d == null || d < 1 || d > 31) return '1-31 required';
                return null;
              },
            )
          else
            AppFormInputField(
              controller: _durationController,
              label: 'Course Duration (Months)',
              hint: '12',
              icon: Icons.timer_rounded,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
        ],
      ),
    );
  }

  Widget _buildStep3(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('REVENUE POLICIES'),
          const SizedBox(height: 12),
          _buildPolicySwitch(
            'Partial Payments',
            'Allow admins to collect flexible amounts',
            _allowPartial,
            (v) => setState(() => _allowPartial = v),
            cs,
          ),
          const SizedBox(height: 12),
          AppFormInputField(
            controller: _lateFeeController,
            label: 'Late Fee (Per Day)',
            hint: 'Optional surcharge',
            icon: Icons.warning_amber_rounded,
            keyboardType: TextInputType.number,
          ),
          if (_planType == FeePlanType.package) ...[
            const SizedBox(height: 32),
            _buildSectionLabel('INSTALLMENT LOGIC'),
            const SizedBox(height: 12),
            _buildPolicySwitch(
              'Installment Plan',
              'Break down total cost into parts',
              _allowInstallments,
              (v) => setState(() => _allowInstallments = v),
              cs,
            ),
            if (_allowInstallments) ...[
              const SizedBox(height: 24),
              AppFormInputField(
                controller: _installmentsController,
                label: 'Total Parts',
                hint: 'e.g. 3',
                icon: Icons.pie_chart_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
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
                  setState(() => _currentStep--);
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
              onPressed: _next,
              busy: _saving,
              label: _currentStep < 2 ? 'Next Phase' : (widget.plan == null ? 'Create Architecture' : 'Commit Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(FeePlanType type, String label, IconData icon, ColorScheme cs) {
    final isSelected = _planType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _planType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildPolicySwitch(String title, String sub, bool val, Function(bool) onChanged, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(sub, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(value: val, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    final payload = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'scope': _scope,
      'planType': _planType.name,
      'admissionFee': double.tryParse(_admissionController.text) ?? 0.0,
      'monthlyFee': _planType == FeePlanType.monthly ? (double.tryParse(_monthlyController.text) ?? 0.0) : 0.0,
      'monthlyDueDay': _planType == FeePlanType.monthly ? (int.tryParse(_dueDayController.text) ?? 5) : 5,
      'totalCourseFee': _planType == FeePlanType.package ? (double.tryParse(_totalFeeController.text) ?? 0.0) : 0.0,
      'durationMonths': _planType == FeePlanType.package ? (int.tryParse(_durationController.text)) : null,
      'allowInstallments': _planType == FeePlanType.package ? _allowInstallments : false,
      'installmentCount': (_planType == FeePlanType.package && _allowInstallments) ? (int.tryParse(_installmentsController.text)) : null,
      'lateFeePerDay': double.tryParse(_lateFeeController.text),
      'allowPartialPayment': _allowPartial,
    };

    bool ok;
    if (widget.plan == null) {
      ok = await widget.controller.createPlan(
        name: payload['name'] as String,
        description: payload['description'] as String,
        scope: payload['scope'] as String,
        planType: _planType,
        admissionFee: payload['admissionFee'] as double,
        monthlyFee: payload['monthlyFee'] as double,
        monthlyDueDay: payload['monthlyDueDay'] as int,
        totalCourseFee: payload['totalCourseFee'] as double,
        durationMonths: payload['durationMonths'] as int?,
        allowInstallments: payload['allowInstallments'] as bool,
        installmentCount: payload['installmentCount'] as int?,
        lateFeePerDay: payload['lateFeePerDay'] as double?,
        allowPartialPayment: payload['allowPartialPayment'] as bool,
      );
    } else {
      ok = await widget.controller.updatePlan(widget.plan!.id, payload);
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.controller.errorMessage ?? 'Operation failed')),
        );
      }
    }
  }
}
