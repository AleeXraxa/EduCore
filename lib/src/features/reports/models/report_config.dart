import 'package:flutter/material.dart';

/// Top-level category grouping of all report types.
enum ReportCategory { academic, financial, operational }

/// Every distinct report the system can generate.
enum ReportType {
  // ── Academic ────────────────────────────────────────────────────────────────
  studentList,
  classWiseStudents,

  attendanceByStudent,
  attendanceByClass,
  attendanceSummary,

  examResults,
  testResults,

  // ── Financial ───────────────────────────────────────────────────────────────
  paidFees,
  pendingFees,
  partialFees,
  feeCollectionByDate,
  studentFeeHistory,
  monthlyFeeReport,

  expenseList,
  expenseByCategory,
  monthlyExpenseSummary,

  profitLossMonthly,
  profitLossYearly,

  // ── Operational ─────────────────────────────────────────────────────────────
  staffList,
  classList,
}

/// Metadata associated with each report type.
class ReportMeta {
  const ReportMeta({
    required this.type,
    required this.category,
    required this.label,
    required this.description,
    required this.icon,
    required this.gradient,
    this.requiredFeature,
  });

  final ReportType type;
  final ReportCategory category;
  final String label;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String? requiredFeature;

  static const List<ReportMeta> all = [
    // Academic
    ReportMeta(
      type: ReportType.studentList,
      category: ReportCategory.academic,
      label: 'Student List',
      description: 'Complete student directory with class & status info',
      icon: Icons.people_alt_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      requiredFeature: 'student_reports',
    ),
    ReportMeta(
      type: ReportType.classWiseStudents,
      category: ReportCategory.academic,
      label: 'Class-wise Students',
      description: 'Student breakdown grouped by class',
      icon: Icons.class_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      requiredFeature: 'student_reports',
    ),
    ReportMeta(
      type: ReportType.attendanceByStudent,
      category: ReportCategory.academic,
      label: 'Student Attendance',
      description: 'Individual student attendance records by date range',
      icon: Icons.fact_check_rounded,
      gradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
      requiredFeature: 'attendance_reports',
    ),
    ReportMeta(
      type: ReportType.attendanceByClass,
      category: ReportCategory.academic,
      label: 'Class-wise Attendance',
      description: 'Attendance summary grouped by class',
      icon: Icons.bar_chart_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      requiredFeature: 'attendance_reports',
    ),
    ReportMeta(
      type: ReportType.attendanceSummary,
      category: ReportCategory.academic,
      label: 'Monthly Attendance Summary',
      description: 'Month-by-month attendance rates across all classes',
      icon: Icons.calendar_month_rounded,
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      requiredFeature: 'attendance_reports',
    ),
    ReportMeta(
      type: ReportType.examResults,
      category: ReportCategory.academic,
      label: 'Exam Results',
      description: 'Full results sheet for all exams',
      icon: Icons.assessment_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      requiredFeature: 'exam_reports',
    ),
    ReportMeta(
      type: ReportType.testResults,
      category: ReportCategory.academic,
      label: 'Monthly Test Results',
      description: 'Results for all monthly test assessments',
      icon: Icons.quiz_rounded,
      gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
      requiredFeature: 'exam_reports',
    ),
    // Financial
    ReportMeta(
      type: ReportType.paidFees,
      category: ReportCategory.financial,
      label: 'Paid Fees',
      description: 'All fully paid fee records',
      icon: Icons.check_circle_rounded,
      gradient: [Color(0xFF16A34A), Color(0xFF15803D)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.pendingFees,
      category: ReportCategory.financial,
      label: 'Pending Fees',
      description: 'Outstanding fees not yet collected',
      icon: Icons.pending_actions_rounded,
      gradient: [Color(0xFFDC2626), Color(0xFFB91C1C)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.partialFees,
      category: ReportCategory.financial,
      label: 'Partial Fees',
      description: 'Fees partially paid with remaining balance',
      icon: Icons.hourglass_bottom_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.feeCollectionByDate,
      category: ReportCategory.financial,
      label: 'Fee Collection by Date',
      description: 'Fee payments filtered by custom date range',
      icon: Icons.date_range_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.studentFeeHistory,
      category: ReportCategory.financial,
      label: 'Student Fee History',
      description: 'Complete payment history for a single student',
      icon: Icons.person_search_rounded,
      gradient: [Color(0xFF0D9488), Color(0xFF0F766E)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.monthlyFeeReport,
      category: ReportCategory.financial,
      label: 'Monthly Fee Report',
      description: 'Fee collection breakdown by month',
      icon: Icons.calendar_today_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      requiredFeature: 'fee_reports',
    ),
    ReportMeta(
      type: ReportType.expenseList,
      category: ReportCategory.financial,
      label: 'Expense List',
      description: 'Complete expense ledger with categories and dates',
      icon: Icons.money_off_rounded,
      gradient: [Color(0xFFE11D48), Color(0xFFBE123C)],
      requiredFeature: 'financial_reports',
    ),
    ReportMeta(
      type: ReportType.expenseByCategory,
      category: ReportCategory.financial,
      label: 'Category-wise Expenses',
      description: 'Expenses grouped and totalled by category',
      icon: Icons.pie_chart_rounded,
      gradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      requiredFeature: 'financial_reports',
    ),
    ReportMeta(
      type: ReportType.monthlyExpenseSummary,
      category: ReportCategory.financial,
      label: 'Monthly Expense Summary',
      description: 'Month-by-month expense totals',
      icon: Icons.bar_chart_rounded,
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
      requiredFeature: 'financial_reports',
    ),
    ReportMeta(
      type: ReportType.profitLossMonthly,
      category: ReportCategory.financial,
      label: 'Monthly P&L',
      description: 'Monthly profit and loss: Revenue minus Expenses',
      icon: Icons.trending_up_rounded,
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      requiredFeature: 'financial_reports',
    ),
    ReportMeta(
      type: ReportType.profitLossYearly,
      category: ReportCategory.financial,
      label: 'Yearly P&L',
      description: 'Annual profit and loss summary with trend chart',
      icon: Icons.show_chart_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      requiredFeature: 'financial_reports',
    ),
    // Operational
    ReportMeta(
      type: ReportType.staffList,
      category: ReportCategory.operational,
      label: 'Staff List',
      description: 'All staff members with roles and contact info',
      icon: Icons.badge_rounded,
      gradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
      requiredFeature: 'dashboard_analytics',
    ),

    ReportMeta(
      type: ReportType.classList,
      category: ReportCategory.operational,
      label: 'Class List',
      description: 'All active classes with teacher assignments',
      icon: Icons.class_rounded,
      gradient: [Color(0xFF0891B2), Color(0xFF0E7490)],
      requiredFeature: 'dashboard_analytics',
    ),
  ];

  static List<ReportMeta> byCategory(ReportCategory cat) =>
      all.where((r) => r.category == cat).toList();
}

/// Active filters applied to a report generation request.
class ReportFilters {
  ReportFilters({
    this.classId,
    this.className,
    this.studentId,
    this.studentName,
    this.status,
    this.startDate,
    this.endDate,
    this.month,
    this.year,
  });

  String? classId;
  String? className;
  String? studentId;
  String? studentName;
  String? status;
  DateTime? startDate;
  DateTime? endDate;
  String? month; // "YYYY-MM"
  int? year;

  ReportFilters copyWith({
    String? classId,
    String? className,
    String? studentId,
    String? studentName,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? month,
    int? year,
  }) {
    return ReportFilters(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  bool get hasAnyFilter =>
      classId != null ||
      studentId != null ||
      status != null ||
      startDate != null ||
      endDate != null ||
      month != null ||
      year != null;
}

/// A single row of data in the generated report table.
typedef ReportRow = Map<String, dynamic>;
