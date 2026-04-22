import 'dart:io';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/features/students/models/bulk_import_models.dart';
import 'package:educore/src/features/students/services/bulk_student_import_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';

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
    // Show loading
    setState(() => _isProcessing = true);
    
    try {
      final bytes = await _importSvc.generateExcelTemplate(
        activePlans: _allFeePlans,
        activeClasses: _allClasses,
      );

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Student Import Template',
        fileName: 'student_import_template.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        if (mounted) AppToasts.showSuccess(context, message: 'Excel Template saved successfully!');
      }
    } catch (e) {
      if (mounted) AppToasts.showError(context, message: 'Failed to generate template: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Import Completed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'The bulk student onboarding process has finished.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                
                // Result Cards
                _buildReportCard('Total Processed', result.totalRows.toString(), cs.primary, Icons.format_list_bulleted_rounded),
                const SizedBox(height: 12),
                _buildReportCard('Successfully Onboarded', result.successCount.toString(), Colors.green, Icons.person_add_rounded),
                const SizedBox(height: 12),
                _buildReportCard('Failed / Skipped', result.failedCount.toString(), result.failedCount > 0 ? Colors.red : cs.onSurfaceVariant, Icons.error_outline_rounded),
                
                const SizedBox(height: 32),
                AppPrimaryButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.pop(context); // Pop report
                    Navigator.pop(context); // Pop import dialog
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20),
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
                  'Upload Excel file to onboard students. Use dropdowns for Fee Plans.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Excel Template'),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Use dropdowns in template. Do not edit manually.',
                  style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Select File',
            onPressed: _pickFile,
            icon: Icons.add_rounded,
            width: 280,
            variant: AppButtonVariant.secondary,
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
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              _summaryChip('Total: ${_rows.length}', cs.primary),
              const SizedBox(width: 12),
              _summaryChip('Valid: $validCount', Colors.green),
              const SizedBox(width: 12),
              _summaryChip('Errors: $errorCount', Colors.red),
              const Spacer(),
              Icon(Icons.insert_drive_file_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '$_fileName',
                style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _pickFile,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Change File'),
              ),
            ],
          ),
        ),
        // Custom Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
          child: Row(
            children: [
              _headerCell('#', flex: 1),
              _headerCell('Status', flex: 1, center: true),
              _headerCell('Student Name', flex: 3),
              _headerCell('Father Name', flex: 3),
              _headerCell('Roll #', flex: 2),
              _headerCell('Class', flex: 2),
              _headerCell('Fee Plan', flex: 3),
              _headerCell('Potential Errors', flex: 4),
            ],
          ),
        ),
        // Scrollable Rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _rows.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return _buildTableRow(row, cs);
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label, {required int flex, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTableRow(BulkImportRow row, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: row.hasErrors ? Colors.red.withValues(alpha: 0.02) : null,
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(row.rowNumber.toString(), style: TextStyle(color: cs.onSurfaceVariant))),
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(
                row.isValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: row.isValid ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.data['name'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.data['fatherName'] ?? '-',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(flex: 2, child: Text(row.data['rollNo'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 2,
            child: Text(
              row.data['class'] ?? '-',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                row.data['feePlan'] ?? row.data['feePlanId'] ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: row.hasErrors
                ? Text(
                    row.errors.join(', '),
                    style: TextStyle(color: cs.error, fontSize: 12, fontWeight: FontWeight.w500),
                  )
                : const Text(
                    'No issues',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
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
