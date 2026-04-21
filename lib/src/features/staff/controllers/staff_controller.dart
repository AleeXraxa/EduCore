import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/staff_service.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';
import 'package:educore/src/features/features/models/feature_flag.dart';
import 'package:educore/src/features/features/models/feature_group.dart';

class StaffController extends BaseController {
  final StaffService _staffService;
  final FeatureService _featureService;
  final String _academyId;

  StaffController({StaffService? staffService, FeatureService? featureService})
    : _staffService = staffService ?? AppServices.instance.getStaffService,
      _featureService = featureService ?? AppServices.instance.featureService!,
      _academyId = AppServices.instance.authService?.session?.academyId ?? '';

  List<StaffMember> _staffList = [];
  List<StaffMember> get staffList => _staffList;

  List<FeatureFlag> _allFeatures = [];
  List<FeatureFlag> get allFeatures => _allFeatures;

  List<FeatureGroup> _featureGroups = [];
  List<FeatureGroup> get featureGroups => _featureGroups;

  @override
  void dispose() {
    super.dispose();
  }

  /// Fetches staff, features, and groups into local cache (One-time fetch)
  Future<void> load() async {
    if (_academyId.isEmpty) return;
    
    await runBusy(() async {
      try {
        final results = await Future.wait([
          _staffService.getStaff(_academyId),
          _featureService.getFeaturesCached(),
          _featureService.getGroupsCached(),
        ]);

        _staffList = results[0] as List<StaffMember>;
        _allFeatures = results[1] as List<FeatureFlag>;
        _featureGroups = results[2] as List<FeatureGroup>;
      } catch (e) {
        debugPrint('Error loading staff data: $e');
      }
    });
  }

  /// Legacy helper for views expecting 'init'
  void init() => load();

  Future<void> addStaff({
    required String name,
    required String email,
    required String password,
    required String phone,
    required StaffRole role,
    String? customRoleName,
  }) async {
    await runBusy(() async {
      final List<String> defaultFeatures = _getDefaultFeaturesForRole(role);
      await _staffService.createStaff(
        academyId: _academyId,
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        customRoleName: customRoleName,
        assignedFeatureKeys: defaultFeatures,
      );
      await load(); // Refresh local cache
    });
  }

  Future<void> updateStaff(StaffMember staff) async {
    await runBusy(() async {
      await _staffService.updateStaff(_academyId, staff);
      await load(); // Refresh local cache
    });
  }

  Future<void> deleteStaff(String staffId) async {
    await runBusy(() async {
      await _staffService.deleteStaff(_academyId, staffId);
      await load(); // Refresh local cache
    });
  }

  Future<void> toggleStatus(String staffId, bool isActive) async {
    try {
      await runBusy(() async {
        await _staffService.toggleStatus(_academyId, staffId, isActive);
        await load(); // Refresh local cache
      });
    } catch (e) {
      debugPrint('Error toggling staff status: $e');
    }
  }

  Future<void> updatePermissions(
    String staffId,
    List<String> allowed,
    List<String> denied,
  ) async {
    await runBusy(() async {
      await _staffService.updatePermissions(
        academyId: _academyId,
        staffId: staffId,
        allowed: allowed,
        denied: denied,
      );
      await load(); // Refresh local cache
    });
  }

  List<String> _getDefaultFeaturesForRole(StaffRole role) {
    switch (role) {
      case StaffRole.teacher:
        return [
          'student_view',
          'class_view',
          'staff_attendance',
          'exam_entry',
          'timetable_view',
          'homework_management',
        ];
      case StaffRole.accountant:
        return [
          'fee_management',
          'expense_tracking',
          'salary_management',
          'financial_reports',
          'payment_gateway_config',
        ];
      case StaffRole.admin:
        return [
          'staff_add',
          'staff_edit',
          'staff_delete',
          'role_management',
          'staff_attendance',
          'student_add',
          'student_edit',
          'class_management',
          'settings_edit',
          'reports_view',
        ];
      case StaffRole.custom:
        return [];
    }
  }

  /// Applies a role preset to a staff member's permissions
  Future<void> applyRolePreset(String staffId, StaffRole preset) async {
    final features = _getDefaultFeaturesForRole(preset);
    await updatePermissions(staffId, features, []);
  }
}
