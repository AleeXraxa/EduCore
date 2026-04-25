import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/core/services/role_defaults_service.dart';

class FeatureAccessService {
  FeatureAccessService({
    required FeatureService featureService,
    required PlanService planService,
    required SubscriptionService subscriptionService,
    RoleDefaultsService? roleDefaultsService,
  }) : _featureService = featureService,
       _planService = planService,
       _subscriptionService = subscriptionService,
       _roleDefaultsService = roleDefaultsService;

  final FeatureService _featureService;
  final PlanService _planService;
  final SubscriptionService _subscriptionService;
  final RoleDefaultsService? _roleDefaultsService;

  Map<String, List<String>> _roleDefaults = {};

  String? _currentAcademyId;
  String? _currentStaffId;
  bool _isSuperAdmin = false;
  Set<String> _allowedFeatures = {};
  bool _initialized = false;

  final StreamController<Set<String>> _accessStream =
      StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get accessStream => _accessStream.stream;

  bool get isInitialized => _initialized;

  void setSuperAdmin(bool value) {
    _isSuperAdmin = value;
    if (value) {
      _accessStream.add(_allowedFeatures);
    }
  }

  Future<void> init(
    String academyId, {
    String? staffId,
    bool isSuperAdmin = false,
  }) async {
    _currentAcademyId = academyId;
    _currentStaffId = staffId;
    _isSuperAdmin = isSuperAdmin;
    await _load();
    _initialized = true;
    _accessStream.add(_allowedFeatures);
  }

  bool canAccess(String featureKey) {
    if (_isSuperAdmin) {
      debugPrint('FeatureAccess: $featureKey ALLOWED (Super Admin Bypass)');
      return true;
    }

    if (!_initialized) {
      debugPrint(
        'Warning: FeatureAccessService not initialized. Defaulting to FALSE for $featureKey',
      );
      return false;
    }

    final key = _normalize(featureKey);
    final allowed = _allowedFeatures.contains(key);

    debugPrint(
      'FeatureAccess: $featureKey ($key) -> ${allowed ? 'ALLOWED' : 'DENIED'}',
    );
    return allowed;
  }

  String _normalize(String key) {
    return key
        .toLowerCase()
        .replaceAll('students', 'student')
        .replaceAll('fees', 'fee')
        .replaceAll('classes', 'class')
        .replaceAll('exams', 'exam')
        .replaceAll('monthly_tests', 'monthly_test')
        .replaceAll('notifications', 'notification');
  }

  /// Returns the current list of allowed feature keys.
  List<String> getAllowedFeatures() => _allowedFeatures.toList();

  /// Forces a reload from source.
  Future<void> refresh() async {
    if (_currentAcademyId != null) {
      await _load();
      _accessStream.add(_allowedFeatures);
    }
  }

  Future<void> _load() async {
    try {
      // 0. Load Role Defaults (Dynamic)
      if (_roleDefaultsService != null) {
        _roleDefaults = await _roleDefaultsService!.getRoleDefaults();
      }

      // 1. Load Registry (Always needed to know what features exist)
      final registry = await _featureService.watchFeatures().first;
      final activeInRegistry = registry
          .where((f) => f.isActive)
          .map((f) => _normalize(f.key))
          .toSet();

      // OPTION: Super Admin bypass
      if (_isSuperAdmin) {
        _allowedFeatures = activeInRegistry;
        debugPrint(
          'FeatureAccess: Super Admin identified. All active features allowed.',
        );
        return;
      }

      if (_currentAcademyId == null || _currentAcademyId!.isEmpty) {
        _allowedFeatures = {};
        return;
      }

      // 2. Load Subscription & Overrides
      final subscription = await _subscriptionService
          .watchSubscription(_currentAcademyId!)
          .first;

      // 3. Load Plan Default Features
      Set<String> planFeatures = {};
      if (subscription?.planId != null && subscription!.planId.isNotEmpty) {
        final plan = await _planService.getPlan(subscription.planId);
        if (plan != null) {
          planFeatures = plan.features.map(_normalize).toSet();
        }
      }

      // 4. Load Staff Overrides & Role
      Set<String> staffAllowed = {};
      Set<String> staffDenied = {};
      String? staffRole;

      if (_currentStaffId != null) {
        final staffDoc = await FirebaseFirestore.instance
            .collection('academies')
            .doc(_currentAcademyId)
            .collection('staff')
            .doc(_currentStaffId)
            .get();

        if (staffDoc.exists) {
          final data = staffDoc.data()!;
          staffRole = data['role']?.toString();
          staffAllowed =
              (data['assignedFeatureKeys'] as List<dynamic>?)
                  ?.map((e) => _normalize(e.toString()))
                  .toSet() ??
              {};
          staffDenied =
              (data['deniedFeatureKeys'] as List<dynamic>?)
                  ?.map((e) => _normalize(e.toString()))
                  .toSet() ??
              {};
        }
      }

      // 5. Calculate Effective Access
      final allowed = <String>{};
      final overrides = subscription?.overrides;
      final isStaff = _currentStaffId != null;

      for (final key in activeInRegistry) {
        // --- STEP 1: SUBSCRIPTION BOUNDARY (HARD LIMIT) ---
        final inPlan = planFeatures.contains(key);
        final forciblyEnabled = overrides?.isEnabled(key) ?? false;

        // If it's not in the plan AND not explicitly granted via SA override, DENY ALWAYS.
        final academyHasAccess = inPlan || forciblyEnabled;
        if (!academyHasAccess) continue;

        // --- STEP 2: ACADEMY DISABILITY OVERRIDE ---
        if (overrides?.isDisabled(key) ?? false) continue;

        // --- STEP 3: STAFF LEVEL LOGIC ---
        if (isStaff) {
          // 3a. Explicit Deny (Priority 1)
          if (staffDenied.contains(key)) continue;

          // 3b. Explicit Allow (Priority 2)
          if (staffAllowed.contains(key)) {
            allowed.add(key);
            continue;
          }

          // 3c. Fallback to Role Defaults (Priority 3)
          if (staffRole != null && _hasRoleAccess(staffRole, key)) {
            allowed.add(key);
          }
        } else {
          // Owner/Admin inherits all academy-level active features
          allowed.add(key);
        }
      }

      _allowedFeatures = allowed;
      debugPrint(
        'FeatureAccess initialized for $_currentAcademyId: $_allowedFeatures',
      );
    } catch (e) {
      debugPrint('Error loading feature access: $e');
      _allowedFeatures = {};
    }
  }

  /// Helper to check multiple features (logic: ALL must be present)
  bool canAccessAll(List<String> keys) => keys.every(canAccess);

  /// Helper to check multiple features (logic: ANY must be present)
  bool canAccessAny(List<String> keys) => keys.any(canAccess);

  /// Role-based default permissions (Only used as a fallback)
  bool _hasRoleAccess(String role, String featureKey) {
    // Normalize feature key
    final normalized = _normalize(featureKey);

    // These defaults are only applied WITHIN the academy's plan boundary
    final defaults = {
      'institute_admin': {
        'dashboard',
        'academic_year_manage',
        'advanced_analytics',
        'ai_insights',
        'announcement_schedule',
        'announcement_send',
        'attendance_edit',
        'attendance_export',
        'attendance_mark',
        'attendance_monthly_summary',
        'attendance_reports',
        'attendance_view',
        'audit_logs_view',
        'automated_fee_generation',
        'backup_restore',
        'broadcast_message',
        'certificate_create',
        'certificate_download',
        'certificate_generate',
        'certificate_template_manage',
        'certificate_verification',
        'class_create',
        'class_delete',
        'class_edit',
        'class_view',
        'custom_dashboard_builder',
        'dashboard_analytics',
        'data_export_csv',
        'data_export_excel',
        'email_notifications',
        'exam_create',
        'exam_reports',
        'exam_schedule',
        'exams_view',
        'exam_view', // Add both for safety
        'expense_add',
        'expense_delete',
        'expense_edit',
        'expense_reports',
        'expense_view',
        'profit_loss_view',
        'fee_collect',
        'fee_create',
        'fee_delete',
        'fee_discount_apply',
        'fee_edit',
        'fee_history_view',
        'fee_monthly_generate',
        'fee_partial_payment',
        'fee_pending_view',
        'fee_plan_assign',
        'fee_plan_create',
        'fee_plan_delete',
        'fee_plan_edit',
        'fee_plan_view',
        'fee_plan',
        'fee_receipt_generate',
        'fee_reports',
        'fee_view',
        'financial_reports',
        'grade_system_manage',
        'login_access',
        'monthly_test_view',
        'result_edit',
        'result_generate',
        'result_publish',
        'result_view',
        'role_management',
        'section_management',
        'settings_view',
        'smart_notifications',
        'sms_notifications',
        'staff_add',
        'staff_attendance',
        'staff_delete',
        'staff_edit',
        'staff_view',
        'student_create',
        'student_delete',
        'student_edit',
        'student_id_generate',
        'student_profile_documents',
        'student_reports',
        'student_transfer',
        'student_view',
        'subject_management',
        'teacher_assignment',
        'test_bulk_import',
        'test_create',
        'test_delete',
        'test_edit',
        'test_generate_paper',
        'test_marks_entry',
        'test_questions_manage',
        'test_result_download',
        'test_result_view',
        'timetable_setup',
        'user_management', 'whatsapp_api_integration', 'whatsapp_integration',
      },
      'teacher': {
        'dashboard',
        'class_view',
        'student_view',
        'attendance_view',
        'attendance_mark',
        'exams_view',
        'exam_view',
        'monthly_test_view',
        'test_marks_entry',
        'test_result_view',
        'result_view',
      },
      'accountant': {
        'dashboard',
        'fee_view',
        'fee_collect',
        'fee_reports',
        'fee_history_view',
        'expense_view',
        'expense_add',
        'expense_edit',
        'expense_reports',
        'profit_loss_view',
        'financial_reports',
        'settings_view',
      },
    };

    final effectiveDefaults = _roleDefaults.isEmpty ? defaults : _roleDefaults;
    final allowedForRole = effectiveDefaults[role.toLowerCase()] ?? {};

    // Check both original and normalized
    return allowedForRole.contains(featureKey) ||
        allowedForRole.contains(normalized);
  }

  /// Watches effective access for a specific academy.
  /// This is used for real-time UI updates (e.g. in FeatureAccessController).
  Stream<EffectiveFeatureAccess> watchEffectiveAccess(String academyId) {
    // If we're already initialized for this academy, start with current state
    return accessStream.map((keys) => EffectiveFeatureAccess(keys));
  }
}

/// Represents the calculated feature permissions at a specific point in time.
class EffectiveFeatureAccess {
  EffectiveFeatureAccess(this.allowed);
  final Set<String> allowed;

  bool has(String key) => allowed.contains(key);
}
