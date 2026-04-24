import 'package:flutter/foundation.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/notifications/models/app_notification.dart';
import 'package:educore/src/core/mvc/base_controller.dart';

class NotificationsController extends BaseController {
  NotificationsController() {
    _init();
  }

  final _service = AppServices.instance.notificationService;
  final _instituteService = AppServices.instance.instituteService;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  List<Academy> _academies = [];
  List<Academy> get academies => _academies;

  bool _isSending = false;
  bool get isSending => _isSending;

  Future<void> load() async {
    await runBusy(() async {
      try {
        final results = await Future.wait([
          _service?.getNotificationsBatch() ?? Future.value(<AppNotification>[]),
          _instituteService?.getAcademies() ?? Future.value(<Academy>[]),
        ]);

        _notifications = results[0] as List<AppNotification>;
        _academies = results[1] as List<Academy>;
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      }
    });
  }

  void _init() => load();

  Future<void> sendBroadcast({
    required String title,
    required String message,
  }) async {
    if (_isSending) return;
    _setSending(true);
    try {
      await _service?.sendBroadcastNotification(title: title, message: message);
    } finally {
      _setSending(false);
    }
  }

  Future<void> sendTargeted({
    required String academyId,
    required String academyName,
    required String title,
    required String message,
  }) async {
    if (_isSending) return;
    _setSending(true);
    try {
      await _service?.sendTargetedNotification(
        academyId: academyId,
        academyName: academyName,
        title: title,
        message: message,
      );
    } finally {
      _setSending(false);
    }
  }

  Future<void> triggerExpiryReminders() async {
    await _service?.sendExpiryReminders();
  }

  Future<void> deleteNotification(String id) async {
    await _service?.deleteNotification(id);
  }

  void _setSending(bool val) {
    _isSending = val;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
