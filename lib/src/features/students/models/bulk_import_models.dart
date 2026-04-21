import 'package:educore/src/features/students/models/student.dart';

class BulkImportRow {
  BulkImportRow({
    required this.rowNumber,
    required this.data,
    this.student,
    this.errors = const [],
  });

  final int rowNumber;
  final Map<String, String> data;
  Student? student;
  List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get isValid => !hasErrors;
}

class BulkImportResult {
  BulkImportResult({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    this.auditLogId,
  });

  final int totalRows;
  final int successCount;
  final int failedCount;
  final String? auditLogId;
}
