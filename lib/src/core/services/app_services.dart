import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/local_db_service.dart';
import 'package:educore/src/core/services/noop_local_db_service.dart';
import 'package:educore/src/core/services/sqlite_local_db_service.dart';
import 'package:educore/src/core/services/auth_service.dart';
import 'package:educore/src/core/services/noop_prefs_service.dart';
import 'package:educore/src/core/services/prefs_service.dart';
import 'package:educore/src/core/services/shared_prefs_service.dart';
import 'package:educore/src/core/services/seed_service.dart';
import 'package:educore/src/core/services/plan_service.dart';
import 'package:educore/src/core/services/feature_service.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/feature_access_service.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/core/services/admin_users_service.dart';
import 'package:educore/src/core/services/admin_subscriptions_service.dart';
import 'package:educore/src/core/services/admin_payments_service.dart';
import 'package:educore/src/core/services/notification_service.dart';
import 'package:educore/src/core/services/feature_override_service.dart';
import 'package:educore/src/core/services/settings_service.dart';
import 'package:educore/src/core/services/class_service.dart';
import 'package:educore/src/core/services/staff_service.dart';
import 'package:educore/src/core/services/fee_service.dart';
import 'package:educore/src/core/services/fee_plan_service.dart';
import 'package:educore/src/core/services/attendance_service.dart';
import 'package:educore/src/core/services/fee_generation_lock_service.dart';
import 'package:educore/src/core/services/fee_document_service.dart';
import 'package:educore/src/core/services/role_defaults_service.dart';

import 'package:educore/src/features/students/services/student_service.dart';
import 'package:educore/src/features/exams/services/exam_service.dart';
import 'package:educore/src/features/monthly_tests/services/monthly_test_service.dart';
import 'package:educore/src/features/certificates/services/certificate_service.dart';
import 'package:educore/src/features/certificates/services/certificate_template_service.dart';
import 'package:educore/src/features/expenses/services/expense_service.dart';
import 'package:educore/src/features/notifications/services/whatsapp_service.dart';

import 'package:educore/src/core/repositories/user_repository.dart';
import 'package:educore/src/core/repositories/institute_repository.dart';
import 'package:educore/src/core/repositories/payment_repository.dart';
import 'package:educore/src/core/repositories/audit_log_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/firebase_options.dart';

import 'package:flutter/material.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get globalContext => navigatorKey.currentContext;

  late final LocalDbService localDb;
  late final PrefsService prefs;
  FirebaseApp? firebaseApp;
  FirebaseAuth? auth;
  FirebaseFirestore? firestore;
  AuthService? authService;
  SeedService? seedService;
  PlanService? planService;
  FeatureService? featureService;
  SubscriptionService? subscriptionService;
  FeatureAccessService? featureAccessService;
  InstituteService? instituteService;
  ClassService? classService;
  AdminUsersService? adminUsersService;
  AdminSubscriptionsService? adminSubscriptionsService;
  AdminPaymentsService? adminPaymentsService;
  NotificationService? notificationService;
  FeatureOverrideService? featureOverrideService;
  SettingsService? settingsService;
  StaffService? staffService;
  StudentService? studentService;
  FeeService? feeService;
  FeePlanService? feePlanService;
  AttendanceService? attendanceService;
  FeeGenerationLockService? feeGenerationLockService;
  FeeDocumentService? feeDocumentService;
  AuditLogService? auditLogService;
  ExamService? examService;
  MonthlyTestService? monthlyTestService;
  CertificateService? certificateService;
  CertificateTemplateService? certificateTemplateService;
  RoleDefaultsService? roleDefaultsService;
  ExpenseService? expenseService;
  WhatsAppService? whatsappService;
  
  // Repositories
  UserRepository? userRepository;
  InstituteRepository? instituteRepository;
  PaymentRepository? paymentRepository;
  AuditLogRepository? auditLogRepository;

  bool firebaseReady = false;
  Object? firebaseInitError;
  bool _coreInitialized = false;

  // Safe accessors to prevent Null TypeErrors in controllers
  AuditLogService get getAuditLogService {
    if (auditLogService == null) throw StateError('AuditLogService not initialized. Check firebaseReady: $firebaseReady');
    return auditLogService!;
  }

  StaffService get getStaffService {
    if (staffService == null) throw StateError('StaffService not initialized.');
    return staffService!;
  }

  FeatureAccessService get getFeatureAccessService {
    if (featureAccessService == null) throw StateError('FeatureAccessService not initialized.');
    return featureAccessService!;
  }

  InstituteService get getInstituteService {
    if (instituteService == null) throw StateError('InstituteService not initialized.');
    return instituteService!;
  }

  SettingsService get getSettingsService {
    if (settingsService == null) throw StateError('SettingsService not initialized.');
    return settingsService!;
  }

  Future<void> init() async {
    if (!_coreInitialized) {
      const useSqlite = bool.fromEnvironment(
        'EDUCORE_USE_SQLITE',
        defaultValue: false,
      );
      localDb = useSqlite ? SqliteLocalDbService() : NoopLocalDbService();
      await localDb.init();

      try {
        prefs = SharedPrefsService();
        await prefs.init();
      } catch (e) {
        prefs = NoopPrefsService();
        if (kDebugMode) {
          print('Prefs init skipped: $e');
        }
      }

      _coreInitialized = true;
    }

    if (firebaseReady) return;

    try {
      firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      auditLogService = AuditLogService(firestore!);

      authService = AuthService(auth: auth!, firestore: firestore!);
      seedService = SeedService(
        authService: authService!,
        firestore: firestore!,
      );
      planService = PlanService(firestore: firestore!);
      featureService = FeatureService(firestore: firestore!);
      subscriptionService = SubscriptionService(firestore: firestore!);
      
      roleDefaultsService = RoleDefaultsService(firestore: firestore!);
      
      featureAccessService = FeatureAccessService(
        featureService: featureService!,
        planService: planService!,
        subscriptionService: subscriptionService!,
        roleDefaultsService: roleDefaultsService,
      );
      
      instituteService = InstituteService(
        firestore: firestore!,
        primaryApp: firebaseApp!,
        primaryAuth: auth!,
        auditLogService: auditLogService!,
      );
      
      classService = ClassService(
        firestore: firestore!,
        auditLogService: auditLogService!,
        subscriptionService: subscriptionService!,
      );
      
      adminUsersService = AdminUsersService(firestore: firestore!);
      adminSubscriptionsService = AdminSubscriptionsService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );
      adminPaymentsService = AdminPaymentsService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );
      notificationService = NotificationService(
        firestore: firestore!,
        auth: auth!,
      );
      featureOverrideService = FeatureOverrideService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );
      settingsService = SettingsService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );
      
      staffService = StaffService(
        firestore: firestore!,
        userRepository: UserRepository(
          firestore!,
          primaryApp: firebaseApp!,
          primaryAuth: auth!,
        ),
        auditLogService: auditLogService!,
        subscriptionService: subscriptionService!,
      );

      attendanceService = AttendanceService(firestore: firestore!);
      feeGenerationLockService = FeeGenerationLockService(firestore: firestore!);

      feeService = FeeService(
        firestore: firestore!,
        auditLogService: auditLogService!,
        lockService: feeGenerationLockService,
      );
      
      feePlanService = FeePlanService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );

      feeDocumentService = FeeDocumentService(
        firestore: firestore!,
        audit: auditLogService!,
      );

      studentService = StudentService(
        firestore: firestore!,
        subscriptionService: subscriptionService!,
        feeService: feeService!,
        feePlanService: feePlanService!,
        auditLogService: auditLogService!,
      );

      examService = ExamService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );

      monthlyTestService = MonthlyTestService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );

      certificateService = CertificateService(auditLogService!);
      certificateTemplateService = CertificateTemplateService(auditLogService!);

      expenseService = ExpenseService(
        firestore: firestore!,
        auditLogService: auditLogService!,
      );

      whatsappService = WhatsAppService();

      // Initialize Repositories
      userRepository = UserRepository(
        firestore!,
        primaryApp: firebaseApp!,
        primaryAuth: auth!,
      );
      
      final instService = instituteService;
      if (instService != null) {
        instituteRepository =
            InstituteRepository(firestore!, service: instService);
      }
      
      if (adminPaymentsService != null) {
        paymentRepository =
            PaymentRepository(firestore!, service: adminPaymentsService!);
      }
      auditLogRepository = AuditLogRepository(firestore!);
      
      firebaseReady = true;
      firebaseInitError = null;
    } catch (e) {
      firebaseInitError = e;
      if (kDebugMode) {
        print('Firebase init skipped: $e');
      }
    }
  }
}
