import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/expenses/models/expense.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum DateFilterPreset { all, today, last7Days, last30Days, custom }

class ExpensesController extends BaseController {
  final _expenseService = AppServices.instance.expenseService!;
  final _featureAccess = AppServices.instance.featureAccessService!;
  
  StreamSubscription? _expensesSub;

  List<Expense> _allExpenses = [];
  List<Expense> get filteredExpenses => _allExpenses.where((e) {
    if (filterCategory != null && e.category != filterCategory) return false;
    if (filterStartDate != null && e.date.isBefore(filterStartDate!)) return false;
    if (filterEndDate != null && e.date.isAfter(filterEndDate!)) return false;
    if (filterMinAmount != null && e.amount < filterMinAmount!) return false;
    if (filterMaxAmount != null && e.amount > filterMaxAmount!) return false;
    return true;
  }).toList();

  String? filterCategory;
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  double? filterMinAmount;
  double? filterMaxAmount;

  double totalExpenses = 0.0;
  double thisMonthExpenses = 0.0;
  double totalRevenue = 0.0;
  
  DateFilterPreset datePreset = DateFilterPreset.all;
  double get netProfitLoss => totalRevenue - totalExpenses;

  // Permissions
  bool get canAdd => _featureAccess.canAccess('expense_add');
  bool get canEdit => _featureAccess.canAccess('expense_edit');
  bool get canDelete => _featureAccess.canAccess('expense_delete');
  bool get canViewReports => _featureAccess.canAccess('expense_reports');

  void init() {
    _loadData();
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    super.dispose();
  }

  void setFilters({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    filterCategory = category;
    filterStartDate = startDate;
    filterEndDate = endDate;
    filterMinAmount = minAmount;
    filterMaxAmount = maxAmount;
    datePreset = DateFilterPreset.custom;
    notifyListeners();
  }

  void setDatePreset(DateFilterPreset preset, {DateTimeRange? range}) {
    datePreset = preset;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case DateFilterPreset.all:
        filterStartDate = null;
        filterEndDate = null;
        break;
      case DateFilterPreset.today:
        filterStartDate = today;
        filterEndDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case DateFilterPreset.last7Days:
        filterStartDate = today.subtract(const Duration(days: 7));
        filterEndDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case DateFilterPreset.last30Days:
        filterStartDate = today.subtract(const Duration(days: 30));
        filterEndDate = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        break;
      case DateFilterPreset.custom:
        if (range != null) {
          filterStartDate = range.start;
          filterEndDate = range.end;
        }
        break;
    }
    notifyListeners();
  }

  void clearFilters() {
    filterCategory = null;
    filterStartDate = null;
    filterEndDate = null;
    filterMinAmount = null;
    filterMaxAmount = null;
    datePreset = DateFilterPreset.all;
    notifyListeners();
  }

  Future<void> _loadData() async {
    setBusy(true);
    final academyId = AppServices.instance.authService?.session?.academyId;
    if (academyId == null) {
      setBusy(false);
      return;
    }

    try {
      // Stream expenses for real-time list
      _expensesSub?.cancel();
      _expensesSub = _expenseService.watchExpenses(academyId).listen((expenses) {
        _allExpenses = expenses;
        _calculateKPIs();
        notifyListeners();
      });

      // Fetch Total Revenue via FeeService (Handles Windows compatibility and partial payments)
      final feeStats = await AppServices.instance.feeService!.getFeeStats(academyId);
      totalRevenue = (feeStats['totalRevenue'] ?? 0.0).toDouble();
      
      // Fallback if payments structure is slightly different (e.g., 'status' isn't explicitly checked, but all docs in payments are paid fees)
      // Usually payments collection records successful payments. If there's an issue, we can adjust the query.

      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  void _calculateKPIs() {
    totalExpenses = _allExpenses.fold(0.0, (acc, e) => acc + e.amount);
    
    final now = DateTime.now();
    thisMonthExpenses = _allExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  Future<void> addExpense(Expense expense) async {
    final academyId = AppServices.instance.authService?.session?.academyId;
    final staffId = AppServices.instance.authService!.currentUser?.uid;
    if (academyId == null || staffId == null) return;
    
    await _expenseService.addExpense(academyId, expense, staffId);
  }

  Future<void> updateExpense(Expense expense) async {
    final academyId = AppServices.instance.authService?.session?.academyId;
    final staffId = AppServices.instance.authService!.currentUser?.uid;
    if (academyId == null || staffId == null) return;

    await _expenseService.updateExpense(academyId, expense, staffId);
  }

  Future<void> deleteExpense(String expenseId) async {
    final academyId = AppServices.instance.authService?.session?.academyId;
    final staffId = AppServices.instance.authService!.currentUser?.uid;
    if (academyId == null || staffId == null) return;

    await _expenseService.deleteExpense(academyId, expenseId, staffId);
  }
}
