import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/features/reports/models/report_config.dart';
import 'package:flutter/foundation.dart';

/// Central service responsible for querying Firestore and returning
/// structured report data.  All queries are scoped to [academyId] and
/// use minimal reads (paginated or aggregate where possible).
class ReportService {
  ReportService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _fs = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _fs;
  final AuditLogService _audit;

  // ─── helpers ──────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _fees(String aid) =>
      _fs.collection('academies').doc(aid).collection('fees');

  CollectionReference<Map<String, dynamic>> _students(String aid) =>
      _fs.collection('academies').doc(aid).collection('students');

  CollectionReference<Map<String, dynamic>> _expenses(String aid) =>
      _fs.collection('academies').doc(aid).collection('expenses');

  CollectionReference<Map<String, dynamic>> _staff(String aid) =>
      _fs.collection('academies').doc(aid).collection('staff');

  CollectionReference<Map<String, dynamic>> _classes(String aid) =>
      _fs.collection('academies').doc(aid).collection('classes');

  CollectionReference<Map<String, dynamic>> _attendance(String aid) =>
      _fs.collection('academies').doc(aid).collection('attendance');

  CollectionReference<Map<String, dynamic>> _exams(String aid) =>
      _fs.collection('academies').doc(aid).collection('exams');

  CollectionReference<Map<String, dynamic>> _examResults(String aid) =>
      _fs.collection('academies').doc(aid).collection('results');

  CollectionReference<Map<String, dynamic>> _tests(String aid) =>
      _fs.collection('academies').doc(aid).collection('monthlyTests');

  CollectionReference<Map<String, dynamic>> _testResults(String aid) =>
      _fs.collection('academies').doc(aid).collection('testResults');

  CollectionReference<Map<String, dynamic>> _certificates(String aid) =>
      _fs.collection('academies').doc(aid).collection('certificates');

  CollectionReference<Map<String, dynamic>> _auditLogs(String aid) =>
      _fs.collection('academies').doc(aid).collection('auditLogs');

  // ─── audit ────────────────────────────────────────────────────────────────

  Future<void> logReportGenerated(String reportLabel) async {
    try {
      await _audit.logAction(
        action: 'report_generated',
        module: 'reports',
        targetId: reportLabel,
        targetType: 'report',
        metadata: {'reportLabel': reportLabel},
        severity: AuditSeverity.info,
      );
    } catch (e) {
      debugPrint('Audit log failed: $e');
    }
  }

  Future<void> logReportExported(String reportLabel, String format) async {
    try {
      await _audit.logAction(
        action: 'report_exported',
        module: 'reports',
        targetId: reportLabel,
        targetType: 'report',
        metadata: {'reportLabel': reportLabel, 'format': format},
        severity: AuditSeverity.info,
      );
    } catch (e) {
      debugPrint('Audit log failed: $e');
    }
  }


  // ─── Student Reports ──────────────────────────────────────────────────────

  Future<List<ReportRow>> getStudentList(
    String academyId,
    ReportFilters filters,
  ) async {
    Query<Map<String, dynamic>> q = _students(academyId);
    if (filters.classId != null) {
      q = q.where('classId', isEqualTo: filters.classId);
    }
    if (filters.status != null) {
      q = q.where('status', isEqualTo: filters.status);
    }
    final snap = await q.get();
    
    final rows = snap.docs.map((d) {
      final data = d.data();
      return {
        'Roll No': data['rollNo'] ?? '-',
        'Name': data['name'] ?? '',
        'Class': data['className'] ?? '',
        'Contact': data['contactNumber'] ?? '',
        'Status': data['status'] ?? 'active',
        'Enrolled': _fmtTs(data['createdAt']),
      };
    }).toList();

    // Sort by Roll No (Low to High)
    rows.sort((a, b) {
      final r1 = a['Roll No'].toString();
      final r2 = b['Roll No'].toString();
      
      final n1 = int.tryParse(r1);
      final n2 = int.tryParse(r2);
      
      if (n1 != null && n2 != null) {
        return n1.compareTo(n2); // Ascending
      }
      return r1.compareTo(r2); // String ascending fallback
    });

    return rows;
  }

  Future<List<ReportRow>> getAttendanceSummary(
    String academyId,
    ReportFilters filters,
  ) async {
    // Note: Removed orderBy('date') to avoid index requirement for simple summary
    Query<Map<String, dynamic>> q = _attendance(academyId);
    if (filters.startDate != null) {
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!),
      );
    }
    if (filters.endDate != null) {
      q = q.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!),
      );
    }
    if (filters.classId != null) {
      q = q.where('classId', isEqualTo: filters.classId);
    }
    
    final snap = await q.limit(2000).get();

    // Fetch students to get roll numbers for mapping
    final studentSnap = await _students(academyId).get();
    final rollMap = {
      for (var d in studentSnap.docs) d.id: d.data()['rollNo']?.toString() ?? '-'
    };

    // Aggregate per student
    final Map<String, Map<String, dynamic>> byStudent = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final studentId = data['studentId'] as String? ?? '';
      if (studentId.isEmpty) continue;

      final status = data['status'] as String? ?? 'none';
      if (status == 'none') continue;

      byStudent.putIfAbsent(
          studentId,
          () => {
                'Roll No': rollMap[studentId] ?? '-',
                'Name': data['studentName'] ?? studentId,
                'Class': data['className'] ?? '',
                'Present': 0,
                'Absent': 0,
                'Leave': 0,
                'Total': 0,
              });

      byStudent[studentId]!['Total'] =
          (byStudent[studentId]!['Total'] as int) + 1;

      if (status == 'present') {
        byStudent[studentId]!['Present'] =
            (byStudent[studentId]!['Present'] as int) + 1;
      } else if (status == 'absent') {
        byStudent[studentId]!['Absent'] =
            (byStudent[studentId]!['Absent'] as int) + 1;
      } else if (status == 'leave') {
        byStudent[studentId]!['Leave'] =
            (byStudent[studentId]!['Leave'] as int) + 1;
      }
    }

    final rows = byStudent.values.map((row) {
      final total = (row['Total'] as int);
      final present = (row['Present'] as int);
      final pct = total == 0 ? 0 : (present / total * 100).round();
      return {...row, 'Attendance %': '$pct%'};
    }).toList();

    // Sort by Roll No (Low to High)
    rows.sort((a, b) {
      final r1 = a['Roll No'].toString();
      final r2 = b['Roll No'].toString();
      final n1 = int.tryParse(r1);
      final n2 = int.tryParse(r2);
      if (n1 != null && n2 != null) return n1.compareTo(n2);
      return r1.compareTo(r2);
    });

    return rows;
  }

  Future<List<ReportRow>> getMonthlyAttendanceSummary(
    String academyId,
    ReportFilters filters,
  ) async {
    Query<Map<String, dynamic>> q = _attendance(academyId);
    final snap = await q.limit(5000).get();

    final Map<String, Map<String, dynamic>> byMonth = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['date'] as Timestamp?;
      if (ts == null) continue;
      
      final dt = ts.toDate();
      final month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      
      final status = data['status'] as String? ?? 'none';
      if (status == 'none') continue;

      byMonth.putIfAbsent(month, () => {
        'Month': month,
        'Present': 0,
        'Absent': 0,
        'Leave': 0,
        'Total': 0,
      });

      byMonth[month]!['Total'] = (byMonth[month]!['Total'] as int) + 1;
      if (status == 'present') {
        byMonth[month]!['Present'] = (byMonth[month]!['Present'] as int) + 1;
      } else if (status == 'absent') {
        byMonth[month]!['Absent'] = (byMonth[month]!['Absent'] as int) + 1;
      } else if (status == 'leave') {
        byMonth[month]!['Leave'] = (byMonth[month]!['Leave'] as int) + 1;
      }
    }

    return byMonth.values.toList()..sort((a, b) => b['Month'].compareTo(a['Month']));
  }

  Future<List<ReportRow>> getAttendanceByStudent(
    String academyId,
    ReportFilters filters,
  ) async {
    var q = _attendance(academyId).orderBy('date', descending: true);
    if (filters.studentId != null) {
      q = q.where('studentId', isEqualTo: filters.studentId);
    }
    if (filters.startDate != null) {
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!),
      );
    }
    if (filters.endDate != null) {
      q = q.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!),
      );
    }
    
    final snap = await q.limit(500).get();

    // Fetch student mapping for roll numbers
    final studentSnap = await _students(academyId).get();
    final rollMap = {
      for (var d in studentSnap.docs) d.id: d.data()['rollNo']?.toString() ?? '-'
    };

    final rows = snap.docs.map((d) {
      final data = d.data();
      final sid = data['studentId'] as String? ?? '';
      return {
        'Date': _fmtTs(data['date']),
        'Roll No': rollMap[sid] ?? '-',
        'Student': data['studentName'] ?? '',
        'Class': data['className'] ?? '',
        'Status': (data['status'] as String? ?? 'none').toUpperCase(),
      };
    }).toList();

    // If showing many students, sort by Roll No then Date
    if (filters.studentId == null) {
      rows.sort((a, b) {
        final r1 = a['Roll No'].toString();
        final r2 = b['Roll No'].toString();
        final n1 = int.tryParse(r1);
        final n2 = int.tryParse(r2);
        
        int cmp = 0;
        if (n1 != null && n2 != null) cmp = n1.compareTo(n2);
        else cmp = r1.compareTo(r2);
        
        if (cmp != 0) return cmp;
        return b['Date'].compareTo(a['Date']); // Date descending for same roll
      });
    }

    return rows;
  }

  Future<List<ReportRow>> getAttendanceByClass(
    String academyId,
    ReportFilters filters,
  ) async {
    return getAttendanceSummary(academyId, filters);
  }

  Future<List<ReportRow>> getFeeReport(
    String academyId,
    ReportFilters filters, {
    String? statusFilter,
  }) async {
    var q = _fees(academyId).orderBy('createdAt', descending: true);
    if (statusFilter != null) {
      q = q.where('status', isEqualTo: statusFilter);
    }
    if (filters.classId != null) {
      q = q.where('classId', isEqualTo: filters.classId);
    }
    if (filters.startDate != null) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!),
      );
    }
    if (filters.endDate != null) {
      q = q.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!),
      );
    }
    if (filters.month != null) {
      q = q.where('month', isEqualTo: filters.month);
    }
    if (filters.studentId != null) {
      q = q.where('studentId', isEqualTo: filters.studentId);
    }
    final snap = await q.limit(500).get();

    // Fetch students to get roll numbers for mapping
    final studentSnap = await _students(academyId).get();
    final rollMap = {
      for (var d in studentSnap.docs) d.id: d.data()['rollNo']?.toString() ?? '-'
    };

    final rows = snap.docs.map((d) {
      final data = d.data();
      final sid = data['studentId'] as String? ?? '';
      final final_ = (data['finalAmount'] as num?)?.toDouble() ?? 0.0;
      final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      return {
        'Roll No': rollMap[sid] ?? '-',
        'Student': data['studentName'] ?? '',
        'Class': data['className'] ?? '',
        'Type': data['type'] ?? '',
        'Title': data['title'] ?? '',
        'Total (Rs.)': final_.toStringAsFixed(2),
        'Paid (Rs.)': paid.toStringAsFixed(2),
        'Balance (Rs.)': (final_ - paid).toStringAsFixed(2),
        'Status': data['status'] ?? '',
        'Month': data['month'] ?? '',
        'Due Date': _fmtTs(data['dueDate']),
      };
    }).toList();

    // If multiple students are shown, sort by Roll No then date
    if (filters.studentId == null) {
      rows.sort((a, b) {
        final r1 = a['Roll No'].toString();
        final r2 = b['Roll No'].toString();
        final n1 = int.tryParse(r1);
        final n2 = int.tryParse(r2);
        
        int cmp = 0;
        if (n1 != null && n2 != null) cmp = n1.compareTo(n2);
        else cmp = r1.compareTo(r2);
        
        if (cmp != 0) return cmp;
        return 0; // Maintain original sort (createdAt) for same student
      });
    }

    return rows;
  }

  Future<List<ReportRow>> getExpenseReport(
    String academyId,
    ReportFilters filters,
  ) async {
    var q = _expenses(academyId).orderBy('date', descending: true);
    if (filters.startDate != null) {
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!),
      );
    }
    if (filters.endDate != null) {
      q = q.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!),
      );
    }
    final snap = await q.limit(500).get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'Title': data['title'] ?? '',
        'Category': data['category'] ?? '',
        'Amount (Rs.)': (data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00',
        'Payment Method': data['paymentMethod'] ?? '',
        'Date': _fmtTs(data['date']),
        'Description': data['description'] ?? '',
      };
    }).toList();
  }

  Future<List<ReportRow>> getExpenseByCategory(
    String academyId,
    ReportFilters filters,
  ) async {
    final rows = await getExpenseReport(academyId, filters);
    final Map<String, double> totals = {};
    for (final row in rows) {
      final cat = row['Category'] as String? ?? 'Misc';
      final amt =
          double.tryParse(row['Amount (Rs.)'] as String? ?? '0') ?? 0.0;
      totals[cat] = (totals[cat] ?? 0) + amt;
    }
    return totals.entries.map((e) => {
      'Category': e.key,
      'Total (Rs.)': e.value.toStringAsFixed(2),
    }).toList()
      ..sort((a, b) => double.parse(b['Total (Rs.)'] as String)
          .compareTo(double.parse(a['Total (Rs.)'] as String)));
  }

  Future<List<ReportRow>> getProfitLossMonthly(
    String academyId,
    ReportFilters filters,
  ) async {
    // Revenue per month from fees
    final feesSnap = await _fees(academyId)
        .where('paidAmount', isGreaterThan: 0)
        .get();
    final expSnap = await _expenses(academyId).get();

    final Map<String, double> revenue = {};
    final Map<String, double> expenses = {};

    for (final doc in feesSnap.docs) {
      final data = doc.data();
      final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      String month = data['month'] as String? ?? '';
      if (month.isEmpty) {
        final ts = data['createdAt'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        }
      }
      if (month.isNotEmpty) {
        revenue[month] = (revenue[month] ?? 0) + paid;
      }
    }

    for (final doc in expSnap.docs) {
      final data = doc.data();
      final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final ts = data['date'] as Timestamp?;
      if (ts != null) {
        final dt = ts.toDate();
        final month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        expenses[month] = (expenses[month] ?? 0) + amt;
      }
    }

    final allMonths = {...revenue.keys, ...expenses.keys}.toList()..sort();
    final yearFilter = filters.year;
    return allMonths
        .where((m) => yearFilter == null || m.startsWith('$yearFilter'))
        .map((m) {
      final rev = revenue[m] ?? 0.0;
      final exp = expenses[m] ?? 0.0;
      final pl = rev - exp;
      return {
        'Month': m,
        'Revenue (Rs.)': rev.toStringAsFixed(2),
        'Expenses (Rs.)': exp.toStringAsFixed(2),
        'P&L (Rs.)': pl.toStringAsFixed(2),
        'Status': pl >= 0 ? 'Profit' : 'Loss',
      };
    }).toList();
  }

  Future<List<ReportRow>> getStaffReport(String academyId) async {
    final snap = await _staff(academyId).orderBy('name').get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'Name': data['name'] ?? '',
        'Email': data['email'] ?? '',
        'Role': data['role'] ?? '',
        'Phone': data['phone'] ?? '',
        'Status': data['isActive'] == true ? 'Active' : 'Inactive',
        'Joined': _fmtTs(data['createdAt']),
      };
    }).toList();
  }

  Future<List<ReportRow>> getClassReport(String academyId) async {
    final snap = await _classes(academyId).orderBy('name').get();
    
    // Fetch all students to get accurate counts per class
    final studentSnap = await _students(academyId).get();
    final Map<String, int> classCounts = {};
    for (final doc in studentSnap.docs) {
      final classId = doc.data()['classId'] as String?;
      if (classId != null) {
        classCounts[classId] = (classCounts[classId] ?? 0) + 1;
      }
    }

    return snap.docs.map((d) {
      final data = d.data();
      return {
        'Class Name': data['name'] ?? '',
        'Teacher': data['teacherName'] ?? '',
        'Section': data['section'] ?? '',
        'Student Count': (classCounts[d.id] ?? 0).toString(),
        'Created': _fmtTs(data['createdAt']),
      };
    }).toList();
  }

  Future<List<ReportRow>> getExamResults(
    String academyId,
    ReportFilters filters,
  ) async {
    Query<Map<String, dynamic>> q = _examResults(academyId).orderBy('createdAt', descending: true);
    if (filters.classId != null) {
      q = q.where('classId', isEqualTo: filters.classId);
    }
    
    final snap = await q.limit(500).get();
    
    // We need exam titles, so we'll fetch exams and cache them
    final examCache = <String, String>{};
    final examSnap = await _exams(academyId).get();
    for(var doc in examSnap.docs) {
      examCache[doc.id] = doc.data()['title'] ?? 'Unknown Exam';
    }

    return snap.docs.map((doc) {
      final data = doc.data();
      final obtained = (data['totalObtained'] as num?)?.toDouble() ?? 0.0;
      final total = (data['totalMaxMarks'] as num?)?.toDouble() ?? 0.0;
      final pct = (data['percentage'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'Exam': examCache[data['examId']] ?? 'Exam',
        'Roll No': data['studentRollNo'] ?? '',
        'Student': data['studentName'] ?? '',
        'Obtained': obtained.toStringAsFixed(1),
        'Total': total.toStringAsFixed(1),
        'Percentage': '${pct.toStringAsFixed(1)}%',
        'Grade': data['grade'] ?? '',
        'Status': data['status'] ?? '',
        'Rank': data['rank']?.toString() ?? '-',
      };
    }).toList();
  }

  Future<List<ReportRow>> getTestResults(
    String academyId,
    ReportFilters filters,
  ) async {
    Query<Map<String, dynamic>> q = _testResults(academyId).orderBy('createdAt', descending: true);
    
    final snap = await q.limit(500).get();

    // Fetch tests to get titles and class info
    final testCache = <String, Map<String, dynamic>>{};
    final testSnap = await _tests(academyId).get();
    for(var doc in testSnap.docs) {
      testCache[doc.id] = doc.data();
    }

    return snap.docs.where((doc) {
      if (filters.classId == null) return true;
      final test = testCache[doc.data()['testId']];
      return test?['classId'] == filters.classId;
    }).map((doc) {
      final data = doc.data();
      final test = testCache[data['testId']] ?? {};
      final obtained = (data['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
      final total = (data['totalMarks'] as num?)?.toDouble() ?? 0.0;
      final pct = (data['percentage'] as num?)?.toDouble() ?? 0.0;

      return {
        'Test': test['title'] ?? 'Test',
        'Class': test['className'] ?? '',
        'Roll No': data['studentRollNo'] ?? '',
        'Student': data['studentName'] ?? '',
        'Obtained': obtained.toStringAsFixed(1),
        'Total': total.toStringAsFixed(1),
        'Percentage': '${pct.toStringAsFixed(1)}%',
        'Grade': data['grade'] ?? '',
        'Status': data['status'] ?? '',
      };
    }).toList();
  }

  Future<List<ReportRow>> getCertificateHistory(String academyId) async {
    final snap = await _certificates(academyId)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'Student': data['studentName'] ?? '',
        'Class': data['className'] ?? '',
        'Type': data['type'] ?? '',
        'Title': data['title'] ?? '',
        'Issue Date': _fmtTs(data['issueDate']),
        'Generated At': _fmtTs(data['createdAt']),
        'Authorized By': data['authorizedSignatory'] ?? '',
      };
    }).toList();
  }

  Future<List<ReportRow>> getAuditLogs(String academyId) async {
    final snap = await _auditLogs(academyId)
        .orderBy('timestamp', descending: true)
        .limit(300)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'Action': data['action'] ?? '',
        'Module': data['module'] ?? '',
        'Actor': data['actorId'] ?? '',
        'Description': data['description'] ?? '',
        'Severity': data['severity'] ?? '',
        'Timestamp': _fmtTs(data['timestamp']),
      };
    }).toList();
  }

  // ─── Analytics / Chart Data ───────────────────────────────────────────────

  /// Returns monthly revenue+expense totals for the past [months] months.
  Future<Map<String, List<double>>> getMonthlyTrends(
    String academyId, {
    int months = 6,
  }) async {
    final now = DateTime.now();
    final labels = <String>[];
    final revenue = <double>[];
    final expensesData = <double>[];

    for (int i = months - 1; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      final label = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      labels.add(label);
    }

    // Revenue from fees
    final feesSnap = await _fees(academyId).where('paidAmount', isGreaterThan: 0).get();
    final Map<String, double> revMap = {};
    for (final doc in feesSnap.docs) {
      final data = doc.data();
      final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      String month = data['month'] as String? ?? '';
      if (month.isEmpty) {
        final ts = data['createdAt'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        }
      }
      if (labels.contains(month)) {
        revMap[month] = (revMap[month] ?? 0) + paid;
      }
    }

    // Expenses
    final expSnap = await _expenses(academyId).get();
    final Map<String, double> expMap = {};
    for (final doc in expSnap.docs) {
      final data = doc.data();
      final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final ts = data['date'] as Timestamp?;
      if (ts != null) {
        final dt = ts.toDate();
        final month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        if (labels.contains(month)) {
          expMap[month] = (expMap[month] ?? 0) + amt;
        }
      }
    }

    for (final label in labels) {
      revenue.add(revMap[label] ?? 0);
      expensesData.add(expMap[label] ?? 0);
    }

    return {'labels_indices': List.generate(months, (i) => i.toDouble()), 'revenue': revenue, 'expenses': expensesData};
  }

  Future<Map<String, int>> getStudentStatusBreakdown(String academyId) async {
    final snap = await _students(academyId).get();
    final Map<String, int> breakdown = {};
    for (final doc in snap.docs) {
      final status = (doc.data()['status'] as String?) ?? 'active';
      breakdown[status] = (breakdown[status] ?? 0) + 1;
    }
    return breakdown;
  }

  Future<Map<String, double>> getExpenseCategoryBreakdown(
    String academyId,
  ) async {
    final snap = await _expenses(academyId).get();
    final Map<String, double> breakdown = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final cat = data['category'] as String? ?? 'Misc';
      final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
      breakdown[cat] = (breakdown[cat] ?? 0) + amt;
    }
    return breakdown;
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  String _fmtTs(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is Timestamp) dt = value.toDate();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
