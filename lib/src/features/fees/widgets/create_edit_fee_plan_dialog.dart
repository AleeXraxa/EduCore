import 'package:educore/src/app/theme/app_tokens.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 900),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.plan == null ? 'Create Fee Plan' : 'Edit Fee Plan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Plan Type Toggle
                        _buildFieldLabel('Billing Model'),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: AppRadii.r12,
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _buildTypeToggle(FeePlanType.monthly, 'Monthly')),
                              Expanded(child: _buildTypeToggle(FeePlanType.package, 'Package (Course)')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildFieldLabel('Plan Name'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('e.g. Standard Grade 10 Plan'),
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildFieldLabel('Description'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: _inputDecoration('Briefly describe this plan...'),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Scope'),
                                  AppDropdown<String>(
                                    label: 'Plan Scope',
                                    items: const ['class', 'custom'],
                                    value: _scope,
                                    onChanged: (v) => setState(() => _scope = v!),
                                    itemLabel: (v) => v.toUpperCase(),
                                    prefixIcon: Icons.category_rounded,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(_planType == FeePlanType.monthly ? 'Monthly Due Day' : 'Package Duration'),
                                  if (_planType == FeePlanType.monthly)
                                    TextFormField(
                                      controller: _dueDayController,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('e.g. 5'),
                                      validator: (v) {
                                        final val = int.tryParse(v ?? '');
                                        if (val == null || val < 1 || val > 31) return '1-31 required';
                                        return null;
                                      },
                                    )
                                  else
                                    TextFormField(
                                      controller: _durationController,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('Months (e.g. 12)'),
                                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: AppRadii.r16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'FINANCIAL RULES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Admission Fee'),
                                        TextFormField(
                                          controller: _admissionController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('PKR'),
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(_planType == FeePlanType.monthly ? 'Monthly Fee' : 'Total Course Fee'),
                                        TextFormField(
                                          controller: _planType == FeePlanType.monthly ? _monthlyController : _totalFeeController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('PKR'),
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_planType == FeePlanType.package) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Allow Installments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        value: _allowInstallments,
                                        onChanged: (v) => setState(() => _allowInstallments = v),
                                      ),
                                    ),
                                    if (_allowInstallments) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('No. of Installments'),
                                            TextFormField(
                                              controller: _installmentsController,
                                              keyboardType: TextInputType.number,
                                              decoration: _inputDecoration('e.g. 3'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              _buildFieldLabel('Late Fee Per Day (Optional)'),
                              TextFormField(
                                controller: _lateFeeController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('PKR per day overdue'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        SwitchListTile.adaptive(
                          title: const Text('Allow Partial Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Inst Admins can collect installment cash.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          value: _allowPartial,
                          onChanged: (v) => setState(() => _allowPartial = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    AppPrimaryButton(
                      onPressed: _saving ? () {} : _submit,
                      label: widget.plan == null ? 'Create Plan' : 'Update Plan',
                      busy: _saving,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(FeePlanType type, String label) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _planType == type;

    return GestureDetector(
      onTap: () => setState(() => _planType = type),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      border: const OutlineInputBorder(
        borderRadius: AppRadii.r12,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
