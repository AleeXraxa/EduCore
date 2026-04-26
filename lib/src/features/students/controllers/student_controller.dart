import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';
import 'package:educore/src/features/students/services/student_service.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';

class StudentController extends BaseController {
  final StudentService _studentService;
  final String _academyId;

  StudentController({StudentService? studentService})
      : _studentService = studentService ?? AppServices.instance.studentService!,
        _academyId = AppServices.instance.authService!.session!.academyId;

  final List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  List<Student> get students => _filteredStudents;

  final Set<String> _selectedStudentIds = {};
  Set<String> get selectedStudentIds => _selectedStudentIds;
  List<Student> get selectedStudents => 
      _filteredStudents.where((s) => _selectedStudentIds.contains(s.id)).toList();

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String? _classIdFilter;
  String? get classIdFilter => _classIdFilter;
  String? _statusFilter = 'active';
  String? get statusFilter => _statusFilter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stats for Quick Insights
  int totalCount = 0;
  int activeCount = 0;
  int passoutCount = 0;
  int droppedCount = 0;
  int newAdmissionsCount = 0;

  // Custom Fields
  List<StudentCustomField> _customFieldDefinitions = [];
  List<StudentCustomField> get customFieldDefinitions =>
      _customFieldDefinitions;

  Map<String, dynamic> dynamicFormState = {};

  void resetDynamicForm([Map<String, dynamic>? initialValues]) {
    dynamicFormState = initialValues != null ? Map.from(initialValues) : {};
    notifyListeners();
  }

  void updateDynamicField(String key, dynamic value) {
    dynamicFormState[key] = value;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _allStudents.clear();
    _filteredStudents.clear();
    _lastDoc = null;
    _hasMore = true;
    _selectedStudentIds.clear();
    // Temporarily reset before loading
    totalCount = 0;
    activeCount = 0;
    passoutCount = 0;
    droppedCount = 0;
    newAdmissionsCount = 0;

    await Future.wait([
      _fetchBatch(),
      loadCustomFieldDefinitions(),
      _fetchStats(),
    ]);
  }

  Future<void> loadCustomFieldDefinitions() async {
    _customFieldDefinitions =
        await _studentService.getCustomFieldDefinitions(_academyId);
    notifyListeners();
  }

  Future<void> _fetchStats() async {
    final stats = await _studentService.getStudentStats(_academyId);
    totalCount = stats['total'] ?? 0;
    activeCount = stats['active'] ?? 0;
    passoutCount = stats['passout'] ?? 0;
    droppedCount = stats['dropped'] ?? 0;
    newAdmissionsCount = stats['newAdmissions'] ?? 0;
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedStudentIds.contains(id)) {
      _selectedStudentIds.remove(id);
    } else {
      _selectedStudentIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedStudentIds.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedStudentIds.addAll(_filteredStudents.map((s) => s.id));
    notifyListeners();
  }

  Future<void> _fetchBatch() async {
    _errorMessage = null;
    await runBusy(() async {
      try {
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          // Note: We remove the server-side filtering here to fetch a broader batch
          // that we can then filter locally.
          snapshot = await _studentService.getStudentsBatch(
            academyId: _academyId,
            startAfter: _lastDoc,
            // We pass null to get all students in this batch regardless of status/class
            // so we can filter them locally without re-fetching.
            classIdFilter: null,
            statusFilter: null,
          );
        } on FirebaseException catch (e) {
          if (e.code == 'failed-precondition' ||
              e.message?.contains('index') == true) {
            debugPrint('Firestore Error: $e');
            _errorMessage = 'Using simple view (Index missing)';
            final query = FirebaseFirestore.instance
                .collection('academies')
                .doc(_academyId)
                .collection('students')
                .orderBy('name')
                .limit(20);

            final fallbackQuery =
                _lastDoc != null ? query.startAfterDocument(_lastDoc!) : query;
            snapshot = await fallbackQuery.get();
          } else {
            rethrow;
          }
        }

        if (snapshot.docs.length < 20) {
          _hasMore = false;
        }

        if (snapshot.docs.isNotEmpty) {
          _lastDoc = snapshot.docs.last;

          final fetchedStudents = snapshot.docs
              .map((doc) => Student.fromMap(doc.id, doc.data()))
              .toList();

          _allStudents.addAll(fetchedStudents);
          _applyFilters();
        }
      } catch (e, st) {
        debugPrint('Error fetching students: $e $st');
        _errorMessage = 'Failed to load students';
      }
    });
  }

  void _applyFilters() {
    _filteredStudents = _allStudents.where((s) {
      if (s.status == 'deleted') return false;

      // Search Filter
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.rollNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      // Class Filter
      final matchesClass =
          _classIdFilter == null || s.classId == _classIdFilter;

      // Status Filter
      final matchesStatus = _statusFilter == null || s.status == _statusFilter;

      return matchesSearch && matchesClass && matchesStatus;
    }).toList();

    // Local Sorting - Always keep them sorted by name
    _filteredStudents.sort((a, b) => (a.name).compareTo(b.name));

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

  void onClassFilterChanged(String? classId) {
    final normalized = (classId == 'all' || classId == null) ? null : classId;
    if (_classIdFilter == normalized) return;
    _classIdFilter = normalized;
    _applyFilters();
  }

  void onStatusFilterChanged(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _applyFilters();
  }

  Future<void> fetchMore() async {
    if (!_hasMore || busy) return;
    await _fetchBatch();
  }

  @Deprecated('Use fetchMore instead')
  Future<void> loadMore() => fetchMore();

  Future<bool> addStudent(BuildContext context, Student student) async {
    bool success = false;
    await runGuarded(
      () async {
        await _studentService.createStudent(_academyId, student);
        await loadInitialData();
        success = true;
      },
      context: context,
      loadingMessage: 'Adding Student...',
    );
    return success;
  }

  Future<bool> updateStudent(BuildContext context, Student student) async {
    bool success = false;
    await runGuarded(
      () async {
        await _studentService.updateStudent(_academyId, student);
        await loadInitialData();
        success = true;
      },
      context: context,
      loadingMessage: 'Updating Student...',
    );
    return success;
  }

  Future<bool> deleteStudent(BuildContext context, String studentId) async {
    bool success = false;
    await runGuarded(
      () async {
        await _studentService.softDeleteStudent(_academyId, studentId);
        await loadInitialData();
        success = true;
      },
      context: context,
      loadingMessage: 'Deleting Student...',
    );
    return success;
  }

  Future<bool> updateStatus(
    BuildContext context,
    Student student,
    String newStatus, {
    String? reason,
  }) async {
    bool success = false;
    await runGuarded(
      () async {
        await _studentService.updateStudentStatus(
          _academyId,
          student,
          newStatus,
          reason: reason,
        );
        await loadInitialData();
        success = true;
      },
      context: context,
      loadingMessage: 'Updating Status...',
    );
    return success;
  }

  Future<String> getNextRollNumber() async {
    return await _studentService.getNextRollNumber(_academyId);
  }

  Future<void> addCustomFieldDefinition(StudentCustomField field) async {
    await runBusy(() async {
      await _studentService.createCustomFieldDefinition(_academyId, field);
      await loadCustomFieldDefinitions();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<bool> sendWhatsAppMessage(
    BuildContext context,
    Student student,
    String message,
  ) async {
    final whatsappSvc = AppServices.instance.whatsappService;
    if (whatsappSvc == null) return false;

    final success = await runGuarded<bool>(
      () async {
        final phone = student.phone;
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
          'studentId': student.id,
          'studentName': student.name,
          'type': 'direct_message',
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
        message: 'WhatsApp message sent successfully to ${student.name}.',
      );
    }

    return success ?? false;
  }
}
