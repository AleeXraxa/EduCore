import 'dart:async';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';

import 'package:educore/src/features/settings/models/global_settings.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/core/services/institute_service.dart';

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

  Academy? _academy;

  void _init() {
    final session = _auth?.session;
    if (session == null) return;

    if (session.isSuperAdmin) {
      _subscription = _service?.watchGlobalSettings().listen(_handleData);
    } else {
      _loadAcademy(session.academyId);
      _subscription =
          _service?.watchAcademySettings(session.academyId).listen(_handleData);
    }
  }

  Future<void> _loadAcademy(String aid) async {
    try {
      _academy = await AppServices.instance.getInstituteService.getAcademy(aid);
      // Re-trigger handle data if settings are still default
      if (_settings?.appName == 'Institute Name') {
        _handleData(_settings);
      }
    } catch (_) {}
  }

  void _handleData(GlobalSettings? data) {
    final defaultMethods = {
      'jazzcash': PaymentMethodConfig(isActive: false, number: '', accountTitle: ''),
      'easypaisa': PaymentMethodConfig(isActive: false, number: '', accountTitle: ''),
      'bank': PaymentMethodConfig(isActive: false, accountNumber: '', accountTitle: '', bankName: ''),
    };

    if (data == null) {
      _settings = GlobalSettings(
        appName: isSuperAdmin ? 'EduCore Platform' : (_academy?.name ?? 'Institute Name'),
        appLogoUrl: _academy?.logoUrl ?? '',
        supportEmail: _academy?.email ?? '',
        supportPhone: _academy?.phone ?? '',
        address: _academy?.address ?? '',
        paymentMethods: defaultMethods,
      );
    } else {
      // If doc exists but fields are generic/empty, use academy details as fallback
      _settings = data.copyWith(
        appName: (data.appName == 'EduCore' || data.appName.isEmpty) && !isSuperAdmin
            ? (_academy?.name ?? data.appName)
            : data.appName,
        supportEmail: data.supportEmail.isEmpty ? (_academy?.email ?? '') : data.supportEmail,
        supportPhone: data.supportPhone.isEmpty ? (_academy?.phone ?? '') : data.supportPhone,
        address: data.address.isEmpty ? (_academy?.address ?? '') : data.address,
        appLogoUrl: data.appLogoUrl.isEmpty ? (_academy?.logoUrl ?? '') : data.appLogoUrl,
      );
    }
    notifyListeners();
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
    final session = _auth?.session;
    if (_settings == null || session == null) return;

    await runBusy<void>(() async {
      if (session.isSuperAdmin) {
        await _service?.updateGlobalSettings(
          _settings!,
          userId: _auth?.currentUser?.uid,
        );
      } else {
        await _service?.updateAcademySettings(
          session.academyId,
          _settings!,
          userId: _auth?.currentUser?.uid,
        );
      }
    });
  }

  bool get isSuperAdmin => _auth?.session?.isSuperAdmin ?? false;

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
