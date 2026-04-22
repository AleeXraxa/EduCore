import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/bulk_import_models.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/features/fees/models/fee_plan.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BulkStudentImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Parses the file content into a list of maps.
  Future<List<Map<String, String>>> parseFile(File file, String extension) async {
    if (extension.toLowerCase() == '.csv') {
      final input = file.readAsStringSync();
      final fields = const CsvToListConverter().convert(input);
      if (fields.isEmpty) return [];

      final header = fields[0].map((e) => e.toString().trim()).toList();
      final List<Map<String, String>> result = [];

      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        final Map<String, String> map = {};
        for (var j = 0; j < header.length; j++) {
          if (j < row.length) {
            map[header[j]] = row[j].toString().trim();
          } else {
            map[header[j]] = '';
          }
        }
        result.add(map);
      }
      return result;
    } else if (extension.toLowerCase() == '.xlsx' || extension.toLowerCase() == '.xls') {
      final bytes = file.readAsBytesSync();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final List<Map<String, String>> result = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        if (sheet.maxRows < 1) continue;

        // Skip metadata sheets during reading
        if (table == 'FeePlans' || table == 'Classes' || table == 'Metadata') continue;

        final header = sheet.rows[0].map((e) => e?.value?.toString().trim() ?? '').toList();
        
        for (var i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          final Map<String, String> map = {};
          bool hasData = false;
          for (var j = 0; j < header.length; j++) {
            final value = (j < row.length) ? row[j]?.value?.toString().trim() ?? '' : '';
            if (value.isNotEmpty) hasData = true;
            map[header[j]] = value;
          }
          if (hasData) result.add(map);
        }
        break; // Only first data sheet
      }
      return result;
    }
    return [];
  }

  /// Generates a professional Excel template with dropdown validation.
  Future<List<int>> generateExcelTemplate({
    required List<FeePlan> activePlans,
    required List<InstituteClass> activeClasses,
  }) async {
    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet studentsSheet = workbook.worksheets[0];
    studentsSheet.name = 'Students';
    
    // 1. Setup Headers
    final List<String> headers = [
      'name', 'fatherName', 'phone', 'email', 'rollNo', 'class', 'section', 'feePlan'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      final xlsio.Range range = studentsSheet.getRangeByIndex(1, i + 1);
      range.setText(headers[i]);
      range.cellStyle.bold = true;
      range.cellStyle.backColor = '#EEEEEE';
    }

    // 2. Setup Metadata Sheet
    final xlsio.Worksheet metaSheet = workbook.worksheets.addWithName('Metadata');
    
    // A. Fee Plans
    metaSheet.getRangeByName('A1').setText('Fee Plan Names');
    for (int i = 0; i < activePlans.length; i++) {
      metaSheet.getRangeByIndex(i + 2, 1).setText(activePlans[i].name);
    }
    
    // B. Classes
    metaSheet.getRangeByName('B1').setText('Class Names');
    final List<String> uniqueClassNames = activeClasses.map((c) => c.name).toSet().toList();
    for (int i = 0; i < uniqueClassNames.length; i++) {
      metaSheet.getRangeByIndex(i + 2, 2).setText(uniqueClassNames[i]);
    }

    // C. Sections (Optional but good for guidance)
    metaSheet.getRangeByName('C1').setText('Sections');
    final List<String> uniqueSections = activeClasses.map((c) => c.section).where((s) => s.isNotEmpty).toSet().toList();
    for (int i = 0; i < uniqueSections.length; i++) {
      metaSheet.getRangeByIndex(i + 2, 3).setText(uniqueSections[i]);
    }
    
    // 3. Apply Dropdowns to the Students sheet
    
    // Row 2 to 500 for validation
    final int maxValidationRows = 500;

    // A. Fee Plan Dropdown (Column H)
    final xlsio.DataValidation feePlanValidation = studentsSheet.getRangeByName('H2:H$maxValidationRows').dataValidation;
    feePlanValidation.allowType = xlsio.ExcelDataValidationType.values[3]; // list
    feePlanValidation.dataRange = metaSheet.getRangeByName('A2:A${activePlans.length + 1}');
    feePlanValidation.showErrorBox = true;
    feePlanValidation.errorBoxText = 'Select from dropdown';
    feePlanValidation.errorBoxTitle = 'Invalid Plan';

    // B. Class Dropdown (Column F)
    final xlsio.DataValidation classValidation = studentsSheet.getRangeByName('F2:F$maxValidationRows').dataValidation;
    classValidation.allowType = xlsio.ExcelDataValidationType.values[3]; // list
    classValidation.dataRange = metaSheet.getRangeByName('B2:B${uniqueClassNames.length + 1}');
    classValidation.showErrorBox = true;
    classValidation.errorBoxText = 'Select from dropdown';
    classValidation.errorBoxTitle = 'Invalid Class';

    // C. Section Dropdown (Column G)
    if (uniqueSections.isNotEmpty) {
      final xlsio.DataValidation sectionValidation = studentsSheet.getRangeByName('G2:G$maxValidationRows').dataValidation;
      sectionValidation.allowType = xlsio.ExcelDataValidationType.values[3]; // list
      sectionValidation.dataRange = metaSheet.getRangeByName('C2:C${uniqueSections.length + 1}');
      sectionValidation.showErrorBox = true;
      sectionValidation.errorBoxText = 'Select from dropdown';
      sectionValidation.errorBoxTitle = 'Invalid Section';
    }

    // 4. Formatting Improvements
    studentsSheet.getRangeByName('A2').setText('Sample Student');
    studentsSheet.getRangeByName('E2').setText('EDU - 101');
    
    // Freeze header row
    studentsSheet.getRangeByIndex(2, 1).freezePanes();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  /// Entry point for validation.
  Future<List<BulkImportRow>> validateRows({
    required String academyId,
    required List<Map<String, String>> rawData,
    required List<InstituteClass> allClasses,
    required List<FeePlan> allFeePlans,
  }) async {
    final List<BulkImportRow> validatedRows = [];
    final Set<String> fileRollNos = {};

    // Fetch existing roll numbers to check duplicates against DB
    final existingRollNos = await _getExistingRollNos(academyId);

    for (var i = 0; i < rawData.length; i++) {
      final data = rawData[i];
      final List<String> errors = [];
      
      // 1. Required Fields
      if (data['name']?.isEmpty ?? true) errors.add('Name is required');
      if (data['rollNo']?.isEmpty ?? true) errors.add('Roll No is required');
      if (data['class']?.isEmpty ?? true) errors.add('Class is required');
      
      // Flexible field check for feePlan vs feePlanId
      final rawPlanValue = data['feePlan'] ?? data['feePlanId'] ?? '';
      if (rawPlanValue.isEmpty) errors.add('Fee Plan is required');

      // 2. Class Validation
      InstituteClass? matchedClass;
      if (data['class'] != null && data['class']!.isNotEmpty) {
        final className = data['class']!.toLowerCase();
        final sectionName = (data['section'] ?? '').toLowerCase();
        
        try {
          matchedClass = allClasses.firstWhere((c) {
            final isNameMatch = c.name.toLowerCase() == className;
            final isSectionMatch = sectionName.isEmpty || c.section.toLowerCase() == sectionName;
            return isNameMatch && isSectionMatch;
          });
        } catch (_) {
          errors.add('Class "${data['class']}" ${sectionName.isNotEmpty ? 'Section "$sectionName"' : ''} not found');
        }
      }

      // 3. Fee Plan Validation (Smart Mapping)
      FeePlan? matchedPlan;
      if (rawPlanValue.isNotEmpty) {
        try {
          // Try ID first, then Name
          matchedPlan = allFeePlans.firstWhere(
            (p) => p.id == rawPlanValue || p.name == rawPlanValue,
          );
        } catch (_) {
          errors.add('Invalid Fee Plan selected: "$rawPlanValue"');
        }
      }

      // 4. Duplicate Roll No Check (File)
      final rollNo = data['rollNo']?.trim() ?? '';
      if (rollNo.isNotEmpty) {
        if (fileRollNos.contains(rollNo)) {
          errors.add('Duplicate Roll No in file: $rollNo');
        } else {
          fileRollNos.add(rollNo);
        }

        // 5. Duplicate Roll No Check (DB)
        if (existingRollNos.contains(rollNo)) {
          errors.add('Roll No "$rollNo" already exists in database');
        }
      }

      // 6. Format Validations
      if (data['email'] != null && data['email']!.isNotEmpty) {
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(data['email']!)) {
          errors.add('Invalid Email format');
        }
      }
      if (data['phone'] != null && data['phone']!.isNotEmpty) {
        if (!RegExp(r'^03\d{9}$').hasMatch(data['phone']!)) {
          errors.add('Invalid Phone format (03XXXXXXXXX)');
        }
      }

      Student? student;
      if (errors.isEmpty && matchedClass != null && matchedPlan != null) {
        student = Student(
          id: '', // To be generated by Firestore batch
          name: data['name']!,
          fatherName: data['fatherName'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'],
          rollNo: rollNo,
          classId: matchedClass.id,
          className: matchedClass.displayName,
          admissionDate: DateTime.now(),
          status: 'active',
          feePlanId: matchedPlan.id,
          feePlanName: matchedPlan.name,
          feeMode: (matchedPlan.planType == FeePlanType.package) ? 'package' : 'monthly',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      validatedRows.add(BulkImportRow(
        rowNumber: i + 2, // 1-indexed + header
        data: data,
        student: student,
        errors: errors,
      ));
    }

    return validatedRows;
  }

  Future<BulkImportResult> executeImportWithFees({
    required String academyId,
    required List<BulkImportRow> rows,
    required String actorId,
  }) async {
    int successCount = 0;
    final validRows = rows.where((r) => r.isValid && r.student != null).toList();
    
    if (validRows.isEmpty) {
      return BulkImportResult(totalRows: rows.length, successCount: 0, failedCount: rows.length);
    }

    final feeSvc = AppServices.instance.feeService;
    final feePlanSvc = AppServices.instance.feePlanService!;

    // Process batches
    for (var i = 0; i < validRows.length; i += 500) {
      final end = (i + 500 < validRows.length) ? i + 500 : validRows.length;
      final currentBatchRows = validRows.sublist(i, end);
      
      final batch = _firestore.batch();
      final List<Student> studentsWithIds = [];

      for (var row in currentBatchRows) {
        final docRef = _firestore.collection('academies').doc(academyId).collection('students').doc();
        final student = row.student!.copyWith(id: docRef.id);
        batch.set(docRef, student.toMap());
        studentsWithIds.add(student);
      }

      await batch.commit();
      successCount += currentBatchRows.length;

      // Generate fees for this batch
      for (var student in studentsWithIds) {
        try {
          final plan = await feePlanSvc.getFeePlan(academyId, student.feePlanId);
          if (plan != null && feeSvc != null) {
            // A. Admission Fee
            if (plan.admissionFee > 0) {
              await feeSvc.createAdmissionFee(
                academyId,
                studentId: student.id,
                classId: student.classId,
                feePlanId: plan.id,
                amount: plan.admissionFee,
                studentName: student.name,
                className: student.className,
              );
            }
            // B. Package Fee
            if (plan.planType == FeePlanType.package && plan.totalCourseFee > 0) {
              await feeSvc.createPackageFee(
                academyId,
                studentId: student.id,
                classId: student.classId,
                feePlanId: plan.id,
                amount: plan.totalCourseFee,
                title: '${plan.name} Package Fee',
                studentName: student.name,
                className: student.className,
              );
            }
          }
        } catch (e) {
          debugPrint('Error generating fees for student ${student.id}: $e');
        }
      }
    }

    final failedCount = rows.length - successCount;

    final auditId = await _logImport(
      academyId: academyId,
      actorId: actorId,
      totalRows: rows.length,
      successCount: successCount,
      failedCount: failedCount,
    );

    return BulkImportResult(
      totalRows: rows.length,
      successCount: successCount,
      failedCount: failedCount,
      auditLogId: auditId,
    );
  }

  Future<Set<String>> _getExistingRollNos(String academyId) async {
    final snap = await _firestore
        .collection('academies')
        .doc(academyId)
        .collection('students')
        .where('status', isNotEqualTo: 'deleted')
        .get();
    
    return snap.docs
        .map((doc) => (doc.data()['rollNo'] as String? ?? '').trim())
        .where((r) => r.isNotEmpty)
        .toSet();
  }

  Future<String> _logImport({
    required String academyId,
    required String actorId,
    required int totalRows,
    required int successCount,
    required int failedCount,
  }) async {
    final docRef = _firestore
        .collection('academies')
        .doc(academyId)
        .collection('audit_logs')
        .doc();
    
    await docRef.set({
      'type': 'bulk_student_import',
      'actorId': actorId,
      'timestamp': FieldValue.serverTimestamp(),
      'details': {
        'totalRows': totalRows,
        'successCount': successCount,
        'failedCount': failedCount,
      },
    });
    return docRef.id;
  }
}
