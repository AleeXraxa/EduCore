import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/feature_access_service.dart';
import 'package:educore/src/core/services/class_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';

class ClassesController extends BaseController {
  ClassesController({ClassService? classService, FeatureAccessService? featureAccessService})
      : _classService = classService ?? AppServices.instance.classService!,
        _featureAccess = featureAccessService ?? AppServices.instance.featureAccessService!,
        _academyId = AppServices.instance.authService?.session?.academyId ?? '';

  final ClassService _classService;
  final FeatureAccessService _featureAccess;
  final String _academyId;
  
  StreamSubscription<List<InstituteClass>>? _sub;

  List<InstituteClass> _classes = [];
  List<InstituteClass> get classes => _filteredClasses;

  String _searchQuery = '';
  String? get searchQuery => _searchQuery;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Feature Toggles based on Access Service
  bool get canCreate => _featureAccess.canAccess('class_create');
  bool get canEdit => _featureAccess.canAccess('class_edit');
  bool get canDelete => _featureAccess.canAccess('class_delete');
  bool get canManageSections => _featureAccess.canAccess('section_management');

  List<InstituteClass> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    final q = _searchQuery.toLowerCase();
    return _classes.where((c) {
      return c.name.toLowerCase().contains(q) ||
             c.section.toLowerCase().contains(q) ||
             (c.classTeacherName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void load() {
    if (_academyId.isEmpty) {
      _errorMessage = 'Academy context not found.';
      notifyListeners();
      return;
    }
    
    setBusy(true);
    _errorMessage = null;

    _sub?.cancel();
    _sub = _classService.watchClasses(_academyId).listen(
      (data) {
        _classes = data;
        setBusy(false);
      },
      onError: (e) {
        _errorMessage = 'Failed to load classes: $e';
        setBusy(false);
      },
    );
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> createClass({
    required String name,
    required String section,
    String? classTeacherId,
    String? classTeacherName,
  }) async {
    if (!canCreate) {
      _errorMessage = 'Permission denied to create classes.';
      notifyListeners();
      return false;
    }

    bool success = false;
    await runBusy(() async {
      try {
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.createClass(
          academyId: _academyId,
          name: name,
          section: section,
          classTeacherId: classTeacherId,
          classTeacherName: classTeacherName,
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    required bool isActive,
  }) async {
    if (!canEdit) {
      _errorMessage = 'Permission denied to edit classes.';
      notifyListeners();
      return false;
    }

    bool success = false;
    await runBusy(() async {
      try {
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.updateClass(
          academyId: _academyId,
          classId: classId,
          updates: {
            'name': name,
            'section': section,
            'classTeacherId': classTeacherId,
            'classTeacherName': classTeacherName,
            'isActive': isActive,
          },
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
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
        final userId = AppServices.instance.authService?.currentUser?.uid ?? 'unknown';
        await _classService.deleteClass(
          academyId: _academyId,
          classId: classId,
          performedBy: userId,
        );
        success = true;
        _errorMessage = null;
      } catch (e) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    });
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
