import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/core/services/fee_service.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';

class FeesController extends BaseController {
  final FeeService _feeService;
  final String _academyId;

  FeesController({FeeService? feeService})
    : _feeService = feeService ?? AppServices.instance.feeService!,
      _academyId = AppServices.instance.authService!.session!.academyId;

  final List<Fee> _allFees = [];
  List<Fee> _filteredFees = [];
  List<Fee> get fees => _filteredFees;

  final Set<String> _selectedFeeIds = {};
  Set<String> get selectedFeeIds => _selectedFeeIds;
  List<Fee> get selectedFees =>
      _filteredFees.where((f) => _selectedFeeIds.contains(f.id)).toList();

  Map<String, dynamic> _stats = {
    'totalRevenue': 0.0,
    'totalPending': 0.0,
    'typeDistribution': <String, double>{},
  };
  Map<String, dynamic> get stats => _stats;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 50; // Increased batch size for better local filtering

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  String _searchQuery = '';
  FeeType? _currentType;
  FeeStatus? _currentStatus;

  FeeType? get currentType => _currentType;
  FeeStatus? get currentStatus => _currentStatus;

  Future<void> loadInitialData({FeeType? type, FeeStatus? status}) async {
    _currentType = type ?? _currentType;
    _currentStatus = status ?? _currentStatus;
    _lastDoc = null;
    _hasMore = true;
    _allFees.clear();
    _filteredFees.clear();
    _selectedFeeIds.clear();

    await runBusy(() async {
      await Future.wait([_fetchFeesBatch(), fetchStats()]);
    });
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await _fetchFeesBatch();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFeesBatch({
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
  }) async {
    try {
      // Note: We fetch a general batch to allow local filtering
      // but we can still respect the initial filter if the dataset is expected to be huge.
      // However, to follow the "Fetch Once" strategy, we fetch without status filters
      // and handle them locally.
      final fetchedFees = await _feeService.getFees(
        _academyId,
        limit: _pageSize,
        startAfter: _lastDoc,
        studentId: studentId,
        classId: classId,
        type: type,
        status: status,
      );

      if (fetchedFees.length < _pageSize) {
        _hasMore = false;
      }

      if (fetchedFees.isNotEmpty) {
        // Update cursor manually to avoid extra read if possible, but Service expects doc
        // For simplicity, we just use the last fee's id for pagination if the service supports it
        // Or we stick to the DocumentSnapshot if it's required.
        _lastDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('fees')
            .doc(fetchedFees.last.id)
            .get();

        _allFees.addAll(fetchedFees);
        _applyFilters();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching fees batch: $e');
      _hasMore = false;
    }
  }

  void _applyFilters() {
    _filteredFees = _allFees.where((f) {
      // Search Filter (Student Name or Title)
      final matchesSearch =
          _searchQuery.isEmpty ||
          (f.studentName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          f.title.toLowerCase().contains(_searchQuery.toLowerCase());

      // Type Filter
      final matchesType = _currentType == null || f.type == _currentType;

      // Status Filter
      final matchesStatus =
          _currentStatus == null || f.status == _currentStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    // Local Sorting - by Date descending
    _filteredFees.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  Timer? _searchDebounce;

  void onSearchChanged(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void onTypeFilterChanged(FeeType? type) {
    if (_currentType == type) return;
    _currentType = type;
    _applyFilters();
  }

  void onStatusFilterChanged(FeeStatus? status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    _applyFilters();
  }

  void toggleSelection(String id) {
    if (_selectedFeeIds.contains(id)) {
      _selectedFeeIds.remove(id);
    } else {
      _selectedFeeIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedFeeIds.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedFeeIds.addAll(_filteredFees.map((f) => f.id));
    notifyListeners();
  }

  /// Legacy fetch - wrapper around batch for compatibility
  @Deprecated('Use loadInitialData or loadMore')
  Future<void> fetchFees({
    String? studentId,
    String? classId,
    FeeType? type,
    FeeStatus? status,
  }) async {
    _lastDoc = null;
    _hasMore = true;
    _allFees.clear();
    await _fetchFeesBatch(
      studentId: studentId,
      classId: classId,
      type: type,
      status: status,
    );
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _feeService.getFeeStats(_academyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<bool> collectPayment(
    BuildContext context,
    String feeId,
    double amount, {
    PaymentMethod method = PaymentMethod.cash,
    String? note,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;

    // Feature Check
    if (!featureSvc.canAccess('fee_collect')) {
      debugPrint('Access Denied: fee_collect');
      return false;
    }

    // Partial Payment Restriction Check
    if (amount <= 0) return false;

    final fee = _allFees.firstWhere((f) => f.id == feeId);
    if (amount < fee.remainingAmount &&
        !featureSvc.canAccess('fee_partial_payment')) {
      debugPrint('Access Denied: fee_partial_payment');
      return false;
    }

    final success = await runGuarded(
      () async {
        final userId = AppServices.instance.authService!.session!.user.uid;
        await _feeService.collectPayment(
          _academyId,
          feeId: feeId,
          paymentAmount: amount,
          method: method,
          collectedBy: userId,
          note: note,
        );
        await loadInitialData(); // Refresh everything
      },
      context: context,
      loadingMessage: 'Recording Payment...',
    );

    return success != null;
  }

  Future<List<FeeTransaction>> getFeeTransactions(String feeId) async {
    try {
      return await _feeService.getTransactions(_academyId, feeId);
    } catch (e) {
      debugPrint('Error fetching fee transactions: $e');
      return [];
    }
  }

  Future<int> generateMonthlyFees({
    required BuildContext context,
    required String classId,
    required String month,
    double? amount,
    String? overrideReason,
    required String title,
    DateTime? dueDate,
  }) async {
    final featureSvc = AppServices.instance.featureAccessService!;
    if (!featureSvc.canAccess('fee_monthly_generate')) {
      return -1;
    }

    final result = await runGuarded(
      () async {
        final count = await _feeService.generateMonthlyFees(
          _academyId,
          classId: classId,
          month: month,
          amount: amount,
          overrideReason: overrideReason,
          overriddenBy: AppServices.instance.authService!.session!.user.uid,
          title: title,
          dueDate: dueDate,
        );

        await loadInitialData();
        return count;
      },
      context: context,
      loadingMessage: 'Generating Fees...',
    );

    return result ?? -1;
  }

  Future<bool> createOtherFee(BuildContext context, Fee fee) async {
    if (!AppServices.instance.featureAccessService!.canAccess('fee_create')) {
      return false;
    }

    final success = await runGuarded(
      () async {
        await _feeService.createFee(_academyId, fee);
        await loadInitialData();
      },
      context: context,
      loadingMessage: 'Creating Fee Record...',
    );

    return success != null;
  }

  Future<bool> sendWhatsAppReminder(BuildContext context, Fee fee) async {
    final whatsappSvc = AppServices.instance.whatsappService;
    if (whatsappSvc == null) return false;

    final success = await runGuarded<bool>(
      () async {
        // 1. Get Student Phone
        final studentDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('students')
            .doc(fee.studentId)
            .get();

        if (!studentDoc.exists) throw 'Student record not found';
        final phone = studentDoc.data()?['phone'] as String?;
        if (phone == null || phone.isEmpty) throw 'Student has no phone number';

        // 2. Fetch Institute Name from Settings
        final settingsDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('settings')
            .doc('institute')
            .get();

        final instituteName =
            settingsDoc.data()?['appName'] ??
            AppServices.instance.authService?.session?.academyName ??
            'Academy';

        // 3. Formulate Message (Removing Due Date as requested)
        final message =
            'Dear ${fee.studentName ?? 'Student'},\n\n'
            'This is a reminder regarding your pending fee for "${fee.title}".\n'
            'Pending Amount: Rs. ${fee.remainingAmount.toStringAsFixed(0)}\n\n'
            'Please clear your dues at the earliest. Thank you!\n'
            '- $instituteName';

        // 4. Send
        final sent = await whatsappSvc.sendMessage(
          academyId: _academyId,
          to: phone,
          message: message,
        );

        // 4. Log to whatsappLogs
        await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('whatsappLogs')
            .add({
              'recipient': phone,
              'message': message,
              'status': sent ? 'sent' : 'failed',
              'studentId': fee.studentId,
              'studentName': fee.studentName,
              'type': 'fee_reminder',
              'createdAt': FieldValue.serverTimestamp(),
              'sentAt': sent ? FieldValue.serverTimestamp() : null,
            });

        return sent;
      },
      context: context,
      loadingMessage: 'Sending Reminder...',
    );

    if (success == true && context.mounted) {
      AppDialogs.showSuccess(
        context,
        title: 'Reminder Sent',
        message: 'WhatsApp reminder sent successfully to ${fee.studentName}.',
      );
    }

    return success ?? false;
  }

  Future<bool> sendWhatsAppMessage(
    BuildContext context,
    Fee fee,
    String message,
  ) async {
    final whatsappSvc = AppServices.instance.whatsappService;
    if (whatsappSvc == null) return false;

    final success = await runGuarded<bool>(
      () async {
        // Fetch student phone
        final studentDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('students')
            .doc(fee.studentId)
            .get();

        if (!studentDoc.exists) throw 'Student record not found';
        final phone = studentDoc.data()?['phone'] ?? '';
        if (phone.isEmpty) throw 'Student has no phone number';

        final sent = await whatsappSvc.sendMessage(
          academyId: _academyId,
          to: phone,
          message: message,
        );

        // Log to whatsappLogs
        await FirebaseFirestore.instance
            .collection('academies')
            .doc(_academyId)
            .collection('whatsappLogs')
            .add({
              'recipient': phone,
              'message': message,
              'status': sent ? 'sent' : 'failed',
              'studentId': fee.studentId,
              'studentName': fee.studentName,
              'feeId': fee.id,
              'type': 'direct_message_fees',
              'createdAt': FieldValue.serverTimestamp(),
              'sentAt': sent ? FieldValue.serverTimestamp() : null,
            });

        return sent;
      },
      context: context,
      loadingMessage: 'Sending Message...',
    );

    if (success == true && context.mounted) {
      AppDialogs.showSuccess(
        context,
        title: 'Message Sent',
        message: 'WhatsApp message sent successfully to ${fee.studentName}.',
      );
    }

    return success ?? false;
  }
}
