import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/plan_limit_exception.dart';
import 'package:educore/src/core/services/feature_access_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';
import 'package:educore/src/core/services/staff_service.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/core/services/class_service.dart';

class ClassesController extends BaseController {
  ClassesController({
    ClassService? classService,
    FeatureAccessService? featureAccessService,
    StaffService? staffService,
  }) : _classService = classService ?? AppServices.instance.classService!,
       _featureAccess =
           featureAccessService ?? AppServices.instance.featureAccessService!,
       _staffService = staffService ?? AppServices.instance.staffService!,
       _academyId = AppServices.instance.authService?.session?.academyId ?? '';

  final ClassService _classService;
  final FeatureAccessService _featureAccess;
  final StaffService _staffService;
  final String _academyId;

  StreamSubscription<List<InstituteClass>>? _sub;
  StreamSubscription<List<StaffMember>>? _staffSub;

  List<InstituteClass> _classes = [];
  List<StaffMember> _teachers = [];

  List<InstituteClass> get classes => _filteredClasses;
  List<StaffMember> get allStaff => _teachers;
  List<StaffMember> get availableTeachers => _teachers
      .where((t) => t.role == StaffRole.teacher && t.isActive)
      .toList();

  int getTeacherClassCount(String teacherId) {
    return _classes.where((c) => c.teacherIds.contains(teacherId)).length;
  }

  /// Returns true if [teacherId] is already the primary class teacher
  /// in any class other than [excludeClassId].
  bool isAlreadyPrimaryTeacher(String teacherId, {String? excludeClassId}) {
    return _classes.any(
      (c) => c.classTeacherId == teacherId && c.id != excludeClassId,
    );
  }

  /// Returns the display name of the class where [teacherId] is currently
  /// the primary teacher (excluding [excludeClassId]), or null if none.
  String? primaryClassNameOf(String teacherId, {String? excludeClassId}) {
    try {
      final cls = _classes.firstWhere(
        (c) => c.classTeacherId == teacherId && c.id != excludeClassId,
      );
      return cls.displayName;
    } catch (_) {
      return null;
    }
  }

  String _searchQuery = '';
  String? get searchQuery => _searchQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Feature Toggles based on Access Service
  bool get canCreate => _featureAccess.canAccess('class_create');
  bool get canEdit => _featureAccess.canAccess('class_edit');
  bool get canDelete => _featureAccess.canAccess('class_delete');
  bool get canManageSections => _featureAccess.canAccess('section_management');
  bool get canAssignTeachers => _featureAccess.canAccess('teacher_assignment');

  List<InstituteClass> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    final q = _searchQuery.toLowerCase();
    return _classes.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.section.toLowerCase().contains(q) ||
          (c.classTeacherName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Unified fetch for classes and teachers (One-time)
  Future<void> fetch() async {
    if (_academyId.isEmpty) {
      _errorMessage = 'Academy context not found.';
      notifyListeners();
      return;
    }

    await runBusy(() async {
      _errorMessage = null;
      try {
        final results = await Future.wait([
          _classService.getClasses(_academyId),
          _staffService.getStaff(_academyId),
        ]);

        final fetchedClasses = results[0] as List<InstituteClass>;
        _teachers = results[1] as List<StaffMember>;

        // Dynamically compute exact student counts using Firestore Aggregations
        // Eliminates data-drift from incremental DB counters. Fast via metadata indexing.
        final firestore = FirebaseFirestore.instance;
        _classes = await Future.wait(
          fetchedClasses.map((cls) async {
            final countSnap = await firestore
                .collection('academies')
                .doc(_academyId)
                .collection('students')
                .where('classId', isEqualTo: cls.id)
                .where('status', isEqualTo: 'active')
                .count()
                .get();

            return cls.copyWith(studentCount: countSnap.count ?? 0);
          }),
        );
      } catch (e) {
        _errorMessage = 'Failed to load modules: $e';
      }
    });
  }

  /// Legacy helper for views expecting 'load'
  void load() => fetch();

  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  Future<bool> createClass({
    required String name,
    required String section,
    String? classTeacherId,
    String? classTeacherName,
    required String feePlanId,
    required String feePlanName,
  }) async {
    if (!canCreate) {
      _errorMessage = 'Permission denied to create classes.';
      notifyListeners();
      return false;
    }

    // Fast in-memory pre-flight: check before hitting Firestore
    if (classTeacherId != null &&
        isAlreadyPrimaryTeacher(classTeacherId)) {
      final conflict = primaryClassNameOf(classTeacherId);
      _errorMessage =
          'This teacher is already the primary teacher of "$conflict". '
          'A teacher can only be the primary teacher of one class at a time.';
      notifyListeners();
      return false;
    }

    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.createClass(
          academyId: _academyId,
          name: name,
          section: section,
          classTeacherId: classTeacherId,
          classTeacherName: classTeacherName,
          feePlanId: feePlanId,
          feePlanName: feePlanName,
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is PlanLimitExceededException) rethrow;
      }
    });
    return success;
  }

  Future<bool> updateClass({
    required String classId,
    required String name,
    required String section,
    String? classTeacherId,
    String? classTeacherName,
    String? feePlanId,
    String? feePlanName,
    required bool isActive,
  }) async {
    if (!canEdit) {
      _errorMessage = 'Permission denied to edit classes.';
      notifyListeners();
      return false;
    }

    // Fast in-memory pre-flight: check before hitting Firestore
    if (classTeacherId != null &&
        isAlreadyPrimaryTeacher(classTeacherId, excludeClassId: classId)) {
      final conflict =
          primaryClassNameOf(classTeacherId, excludeClassId: classId);
      _errorMessage =
          'This teacher is already the primary teacher of "$conflict". '
          'A teacher can only be the primary teacher of one class at a time.';
      notifyListeners();
      return false;
    }

    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.updateClass(
          academyId: _academyId,
          classId: classId,
          updates: {
            'name': name,
            'section': section,
            'classTeacherId': classTeacherId,
            'classTeacherName': classTeacherName,
            'feePlanId': feePlanId,
            'feePlanName': feePlanName,
            'isActive': isActive,
          },
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    });
    return success;
  }

  Future<bool> deleteClass(String classId) async {
    if (!canDelete) {
      _errorMessage = 'Permission denied to delete classes.';
      notifyListeners();
      return false;
    }

    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.deleteClass(
          academyId: _academyId,
          classId: classId,
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    });
    return success;
  }

  Future<bool> assignClassTeacher(
    String classId,
    String teacherId,
    String teacherName,
  ) async {
    if (!canAssignTeachers) return false;
    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.assignClassTeacher(
          academyId: _academyId,
          classId: classId,
          teacherId: teacherId,
          teacherName: teacherName,
          performedBy: userId,
        );
        success = true;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
    return success;
  }

  Future<bool> assignMultipleTeachers(
    String classId,
    List<String> teacherIds,
  ) async {
    if (!canAssignTeachers) return false;
    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.assignMultipleTeachers(
          academyId: _academyId,
          classId: classId,
          teacherIds: teacherIds,
          performedBy: userId,
        );
        success = true;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
    return success;
  }

  Future<bool> removeTeachers(String classId, List<String> teacherIds) async {
    if (!canAssignTeachers) return false;
    bool success = false;
    await runBusy(() async {
      try {
        final userId =
            AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.removeTeachers(
          academyId: _academyId,
          classId: classId,
          teacherIds: teacherIds,
          performedBy: userId,
        );
        success = true;
        await fetch(); // Refresh local cache
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _staffSub?.cancel();
    super.dispose();
  }
}
