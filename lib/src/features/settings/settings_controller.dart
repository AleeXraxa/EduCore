import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';

class SettingsController extends BaseController {
  SettingsSection _section = SettingsSection.general;
  SettingsSection get section => _section;

  // General
  String platformName = 'EduCore';
  String supportEmail = 'support@tryunity.com';
  String contactNumber = '+92 300 0000000';
  Currency currency = Currency.pkr;
  String timezone = 'Asia/Karachi';

  // Plans
  final List<SubscriptionPlan> plans = <SubscriptionPlan>[
    const SubscriptionPlan(
      id: 'basic',
      name: 'Basic',
      pricePkr: 12000,
      durationDays: 30,
      features: [
        'Student management',
        'Fees + receipts',
        'Attendance',
        'Basic reports',
      ],
    ),
    const SubscriptionPlan(
      id: 'standard',
      name: 'Standard',
      pricePkr: 18000,
      durationDays: 30,
      features: [
        'Everything in Basic',
        'Exams + results',
        'Certificates',
        'Monthly stats',
      ],
    ),
    const SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      pricePkr: 32000,
      durationDays: 30,
      features: [
        'Everything in Standard',
        'Advanced analytics',
        'Priority support',
        'Automation (phase)',
      ],
    ),
  ];

  // Payment settings
  bool enableJazzCash = true;
  bool enableEasyPaisa = true;
  bool enableBankTransfer = true;
  String paymentInstructions =
      'Submit payment proof (screenshot) and reference number. Approval usually takes a few minutes.';

  // Notification settings
  bool enableNotifications = true;
  bool enableEmailNotifications = true;
  bool enablePushNotifications = false;

  // Security
  int sessionTimeoutMinutes = 30;

  // Preferences
  ThemePreference themePreference = ThemePreference.light;
  DateFormatOption dateFormat = DateFormatOption.ymd;

  void selectSection(SettingsSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
  }

  Future<void> save() async {
    await runBusy<void>(() async {
      // Placeholder for Firestore write.
      await Future<void>.delayed(const Duration(milliseconds: 260));
    });
  }

  void addPlan(SubscriptionPlan plan) {
    plans.insert(0, plan);
    notifyListeners();
  }

  void updatePlan(SubscriptionPlan plan) {
    final idx = plans.indexWhere((e) => e.id == plan.id);
    if (idx < 0) return;
    plans[idx] = plan;
    notifyListeners();
  }

  void deletePlan(String id) {
    plans.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

