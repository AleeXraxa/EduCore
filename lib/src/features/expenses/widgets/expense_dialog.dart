import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/expenses/controllers/expenses_controller.dart';
import 'package:educore/src/features/expenses/models/expense.dart';

class ExpenseDialog extends StatefulWidget {
  const ExpenseDialog({
    super.key,
    required this.controller,
    this.expense,
  });

  final ExpensesController controller;
  final Expense? expense;

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  
  String _category = 'Misc';
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();
  
  bool _saving = false;

  final _categories = ['Salaries', 'Rent', 'Electricity', 'Internet', 'Maintenance', 'Transport', 'Marketing', 'Misc'];
  final _paymentMethods = ['Cash', 'Bank Transfer', 'Cheque', 'Credit Card', 'Online'];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleCtrl = TextEditingController(text: e?.title);
    _amountCtrl = TextEditingController(text: e?.amount.toString());
    _descCtrl = TextEditingController(text: e?.description);
    if (e != null) {
      _category = e.category;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
      final isEdit = widget.expense != null;
      
      final expense = Expense(
        id: isEdit ? widget.expense!.id : '',
        title: _titleCtrl.text.trim(),
        category: _category,
        amount: amount,
        date: _date,
        paymentMethod: _paymentMethod,
        description: _descCtrl.text.trim(),
      );

      if (isEdit) {
        await widget.controller.updateExpense(expense);
      } else {
        await widget.controller.addExpense(expense);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.expense != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Expense' : 'Add Expense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _titleCtrl,
                label: 'Title',
                hintText: 'e.g., January Office Rent',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _amountCtrl,
                      label: 'Amount',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        child: Text(DateFormat('MMM dd, yyyy').format(_date)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        AppDropdown<String>(
                          label: 'Category',
                          showLabel: false,
                          value: _category,
                          items: _categories,
                          itemLabel: (c) => c,
                          onChanged: (val) {
                            if (val != null) setState(() => _category = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Method', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        AppDropdown<String>(
                          label: 'Payment Method',
                          showLabel: false,
                          value: _paymentMethod,
                          items: _paymentMethods,
                          itemLabel: (c) => c,
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descCtrl,
                label: 'Description / Notes',
                maxLines: 3,
                hintText: 'Optional details...',
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    label: isEdit ? 'Save Changes' : 'Add Expense',
                    busy: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
