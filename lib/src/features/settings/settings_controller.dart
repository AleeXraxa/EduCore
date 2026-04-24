import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';

import 'package:educore/src/features/settings/models/global_settings.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';

class SettingsController extends BaseController {
  final _service = AppServices.instance.settingsService;
  final _planService = AppServices.instance.planService;
  final _auth = AppServices.instance.authService;

  SettingsSection _section = SettingsSection.general;
  SettingsSection get section => _section;

  GlobalSettings? _settings;
  GlobalSettings? get settings => _settings;

  StreamSubscription? _subscription;

  SettingsController() {
    _init();
  }

  void _init() {
    final academyId = _auth?.session?.academyId;
    if (academyId == null) return;

    _subscription = _service?.watchAcademySettings(academyId).listen((data) {
      _settings =
          data ??
          GlobalSettings(
            appName: 'Institute Name',
            appLogoUrl: '',
            supportEmail: '',
            supportPhone: '',
            paymentMethods: {
              'jazzcash': PaymentMethodConfig(
                isActive: false,
                number: '',
                accountTitle: '',
              ),
              'easypaisa': PaymentMethodConfig(
                isActive: false,
                number: '',
                accountTitle: '',
              ),
              'bank': PaymentMethodConfig(
                isActive: false,
                accountNumber: '',
                accountTitle: '',
                bankName: '',
              ),
            },
          );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }

  void selectSection(SettingsSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
  }

  void updateSettings(GlobalSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> save() async {
    final academyId = _auth?.session?.academyId;
    if (_settings == null || academyId == null) return;
    
    await runBusy<void>(() async {
      await _service?.updateAcademySettings(
        academyId,
        _settings!,
        userId: _auth?.currentUser?.uid,
      );
    });
  }

  // Backward compatibility / Helper getters
  String get platformName => _settings?.appName ?? 'EduCore';
  String get supportEmail => _settings?.supportEmail ?? '';
  String get contactNumber => _settings?.supportPhone ?? '';

  // Placeholder for other settings
  Currency currency = Currency.pkr;
  String timezone = 'Asia/Karachi';
  ThemePreference themePreference = ThemePreference.light;
  DateFormatOption dateFormat = DateFormatOption.ymd;
  int sessionTimeoutMinutes = 30;

  bool enableNotifications = true;
  bool enableEmailNotifications = true;
  bool enablePushNotifications = false;

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await runBusy<void>(() async {
      await _auth?.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }
}
