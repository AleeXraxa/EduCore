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
  late final TextEditingController _lateFeeController;
  
  String _scope = 'class';
  bool _allowPartial = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name);
    _descController = TextEditingController(text: widget.plan?.description);
    _admissionController = TextEditingController(text: widget.plan?.admissionFee.toStringAsFixed(0) ?? '0');
    _monthlyController = TextEditingController(text: widget.plan?.monthlyFee.toStringAsFixed(0) ?? '0');
    _dueDayController = TextEditingController(text: widget.plan?.monthlyDueDay.toString() ?? '5');
    _lateFeeController = TextEditingController(text: widget.plan?.lateFeePerDay?.toStringAsFixed(0));
    
    if (widget.plan != null) {
      _scope = widget.plan!.scope;
      _allowPartial = widget.plan!.allowPartialPayment;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _admissionController.dispose();
    _monthlyController.dispose();
    _dueDayController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
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
                                  _buildFieldLabel('Monthly Due Day'),
                                  TextFormField(
                                    controller: _dueDayController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration('e.g. 5'),
                                    validator: (v) {
                                      final val = int.tryParse(v ?? '');
                                      if (val == null || val < 1 || val > 31) return '1-31 required';
                                      return null;
                                    },
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
                                        _buildFieldLabel('Monthly Fee'),
                                        TextFormField(
                                          controller: _monthlyController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('PKR'),
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      'admissionFee': double.parse(_admissionController.text),
      'monthlyFee': double.parse(_monthlyController.text),
      'monthlyDueDay': int.parse(_dueDayController.text),
      'lateFeePerDay': double.tryParse(_lateFeeController.text),
      'allowPartialPayment': _allowPartial,
    };

    bool ok;
    if (widget.plan == null) {
      ok = await widget.controller.createPlan(
        name: payload['name'] as String,
        description: payload['description'] as String,
        scope: payload['scope'] as String,
        admissionFee: payload['admissionFee'] as double,
        monthlyFee: payload['monthlyFee'] as double,
        monthlyDueDay: payload['monthlyDueDay'] as int,
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
