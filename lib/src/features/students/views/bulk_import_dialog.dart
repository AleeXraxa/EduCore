import 'dart:io';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/features/students/models/bulk_import_models.dart';
import 'package:educore/src/features/students/services/bulk_student_import_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:csv/csv.dart';

class BulkImportDialog extends StatefulWidget {
  const BulkImportDialog({super.key});

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  final _importSvc = BulkStudentImportService();
  bool _isProcessing = false;
  bool _isImporting = false;
  
  List<BulkImportRow> _rows = [];
  String? _fileName;
  File? _selectedFile;

  List<InstituteClass> _allClasses = [];
  List<FeePlan> _allFeePlans = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final academyId = AppServices.instance.authService!.session!.academyId;
    final classesFuture = AppServices.instance.classService!.getClasses(academyId);
    final plansFuture = AppServices.instance.feePlanService!.getFeePlans(academyId);
    
    final results = await Future.wait([classesFuture, plansFuture]);
    _allClasses = results[0] as List<InstituteClass>;
    _allFeePlans = results[1] as List<FeePlan>;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isProcessing = true;
        _fileName = result.files.single.name;
        _selectedFile = File(result.files.single.path!);
      });

      try {
        final extension = '.${_fileName!.split('.').last}';
        final rawData = await _importSvc.parseFile(_selectedFile!, extension);
        
        final academyId = AppServices.instance.authService!.session!.academyId;
        final validated = await _importSvc.validateRows(
          academyId: academyId,
          rawData: rawData,
          allClasses: _allClasses,
          allFeePlans: _allFeePlans,
        );

        setState(() {
          _rows = validated;
          _isProcessing = false;
        });
      } catch (e) {
        if (mounted) {
          AppToasts.showError(context, message: 'Failed to parse file: $e');
          setState(() {
            _isProcessing = false;
            _selectedFile = null;
            _fileName = null;
          });
        }
      }
    }
  }

  Future<void> _downloadTemplate() async {
    final List<List<String>> rows = [
      ['name', 'fatherName', 'phone', 'email', 'rollNo', 'class', 'section', 'feePlanId'],
      ['John Doe', 'Richard Doe', '03001234567', 'john@example.com', '101', 'Grade 10', 'A', 'PLAN_ID_OR_NAME'],
    ];

    String csv = const ListToCsvConverter().convert(rows);
    
    // For now, copy to clipboard as a simple cross-platform way, or use file_picker to save
    // On Windows, we can attempt to save
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Student Import Template',
      fileName: 'student_import_template.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(csv);
      if (mounted) AppToasts.showSuccess(context, message: 'Template saved successfully!');
    }
  }

  Future<void> _startImport() async {
    final validRows = _rows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      AppToasts.showError(context, message: 'No valid rows to import.');
      return;
    }

    setState(() => _isImporting = true);

    final academyId = AppServices.instance.authService!.session!.academyId;
    final actorId = AppServices.instance.authService!.session!.user.uid;

    try {
      final result = await _importSvc.executeImportWithFees(
        academyId: academyId,
        rows: _rows,
        actorId: actorId,
      );

      if (mounted) {
        setState(() => _isImporting = false);
        _showReport(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        AppToasts.showError(context, message: 'Import failed: $e');
      }
    }
  }

  void _showReport(BulkImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reportItem('Total Rows', result.totalRows.toString(), Colors.blue),
            _reportItem('Successfully Imported', result.successCount.toString(), Colors.green),
            _reportItem('Failed Rows', result.failedCount.toString(), Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop report
              Navigator.pop(context); // Pop import dialog
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _reportItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: 700,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(cs),
            const Divider(height: 1),
            Expanded(
              child: _rows.isEmpty && !_isProcessing
                  ? _buildEmptyState(cs)
                  : _buildPreviewArea(cs),
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.group_add_rounded, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bulk Student Import',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Upload CSV/Excel file to onboard students in bulk',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Template'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file_rounded, size: 64, color: cs.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No file selected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please select a CSV or Excel file to begin validation',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Select File',
            onPressed: _pickFile,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme cs) {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing file and validating data...'),
          ],
        ),
      );
    }

    final validCount = _rows.where((r) => r.isValid).length;
    final errorCount = _rows.length - validCount;

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              _summaryChip('Total: ${_rows.length}', cs.primary),
              const SizedBox(width: 12),
              _summaryChip('Valid: $validCount', Colors.green),
              const SizedBox(width: 12),
              _summaryChip('Errors: $errorCount', Colors.red),
              const Spacer(),
              Text('File: $_fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              TextButton(onPressed: _pickFile, child: const Text('Change File')),
            ],
          ),
        ),
        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest.withValues(alpha: 0.5)),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Roll No')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Errors')),
                ],
                rows: _rows.map((row) {
                  return DataRow(
                    color: row.hasErrors 
                        ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.05))
                        : null,
                    cells: [
                      DataCell(Text(row.rowNumber.toString())),
                      DataCell(Icon(
                        row.isValid ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: row.isValid ? Colors.green : Colors.red,
                        size: 20,
                      )),
                      DataCell(Text(row.data['name'] ?? '-')),
                      DataCell(Text(row.data['rollNo'] ?? '-')),
                      DataCell(Text(row.data['class'] ?? '-')),
                      DataCell(
                        row.hasErrors
                            ? Text(
                                row.errors.join(', '),
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              )
                            : const Text('Valid', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    final validCount = _rows.where((r) => r.isValid).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: (validCount > 0 && !_isImporting) ? _startImport : null,
            icon: _isImporting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(_isImporting ? 'Importing...' : 'Import $validCount Students'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
