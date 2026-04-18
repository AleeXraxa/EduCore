import 'package:flutter/material.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';
import 'package:intl/intl.dart';

class GenerateMonthlyFeesDialog extends StatefulWidget {
  final Function({
    required String classId,
    required String month,
    required double amount,
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
  final _titleCtrl = TextEditingController(text: 'Monthly Tuition Fee');
  List<InstituteClass> _classes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classes = await AppServices.instance.classService!.getClasses(academyId);
    setState(() => _classes = classes);
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
              onChanged: (v) => setState(() => _selectedClassId = v),
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
            
            const SizedBox(height: 16),
            AppTextField(
              controller: _amountCtrl,
              label: 'Amount (Rs.)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee_rounded,
            ),
            
            const SizedBox(height: 32),
            AppPrimaryButton(
              label: 'Generate Bulk Fees',
              icon: Icons.flash_on_rounded,
              busy: _isLoading,
              onPressed: () async {
                if (_selectedClassId == null || _amountCtrl.text.isEmpty) return;
                
                setState(() => _isLoading = true);
                await widget.onGenerate(
                  classId: _selectedClassId!,
                  month: DateFormat('yyyy-MM').format(_selectedMonth),
                  amount: double.parse(_amountCtrl.text),
                  title: _titleCtrl.text,
                );
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
