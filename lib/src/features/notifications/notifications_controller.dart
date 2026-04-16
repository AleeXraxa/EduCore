import 'dart:async';
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

  StreamSubscription? _notificationsSub;
  StreamSubscription? _academiesSub;

  void _init() {
    setBusy(true);
    _notificationsSub = _service?.watchNotifications().listen((data) {
      _notifications = data;
      setBusy(false);
      notifyListeners();
    });

    _academiesSub = _instituteService?.watchAcademies().listen((data) {
      _academies = data;
      notifyListeners();
    });
  }

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
    _notificationsSub?.cancel();
    _academiesSub?.cancel();
    super.dispose();
  }
}
