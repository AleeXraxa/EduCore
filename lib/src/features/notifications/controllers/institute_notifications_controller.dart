import 'dart:async';
import 'package:flutter/material.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/notifications/models/whatsapp_message.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/staff/models/staff_member.dart';

class InstituteNotificationsController extends BaseController {
  InstituteNotificationsController() {
    _init();
  }

  final _whatsappService = AppServices.instance.whatsappService;
  final _firestore = AppServices.instance.firestore!;

  String? _academyId;
  String? get academyId => _academyId;

  // Connection State
  String _whatsappStatus = 'checking';
  String get whatsappStatus => _whatsappStatus;

  String? _qrCode;
  String? get qrCode => _qrCode;

  // Logs & Stats
  List<WhatsAppMessage> _messages = [];
  List<WhatsAppMessage> get messages => _messages;

  int _sentToday = 0;
  int get sentToday => _sentToday;

  int _failedCount = 0;
  int get failedCount => _failedCount;

  // Data for selection
  List<Student> _students = [];
  List<Student> get students => _students;

  List<StaffMember> _staff = [];
  List<StaffMember> get staff => _staff;

  StreamSubscription? _logsSub;

  void _init() {
    _academyId = AppServices.instance.authService?.session?.academyId;
    if (_academyId != null) {
      _checkStatus();
      _loadData();
      _listenToLogs();
    }
  }

  Future<void> _checkStatus() async {
    if (_academyId == null) return;
    try {
      final res = await _whatsappService?.getStatus(_academyId!);
      _whatsappStatus = res?['status'] ?? 'unknown';
      notifyListeners();
    } catch (e) {
      _whatsappStatus = 'error';
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    if (_academyId == null) return;
    await runBusy(() async {
      try {
        final results = await Future.wait([
          _firestore
              .collection('academies')
              .doc(_academyId)
              .collection('students')
              .get(),
          _firestore
              .collection('academies')
              .doc(_academyId)
              .collection('staff')
              .get(),
        ]);

        _students = results[0].docs
            .map((d) => Student.fromMap(d.id, d.data()))
            .toList();
        _staff = results[1].docs
            .map((d) => StaffMember.fromFirestore(d))
            .toList();
      } catch (e) {
        debugPrint('Error loading selection data: $e');
      }
    });
  }

  void _listenToLogs() {
    if (_academyId == null) return;
    _logsSub?.cancel();

    _logsSub = _firestore
        .collection('academies')
        .doc(_academyId)
        .collection('whatsappLogs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
          _messages = snap.docs
              .map((d) => WhatsAppMessage.fromFirestore(d))
              .toList();

          // Calculate stats
          final today = DateTime.now();
          _sentToday = _messages
              .where(
                (m) =>
                    m.status == WhatsAppMessageStatus.sent &&
                    m.createdAt.day == today.day &&
                    m.createdAt.month == today.month &&
                    m.createdAt.year == today.year,
              )
              .length;

          _failedCount = _messages
              .where((m) => m.status == WhatsAppMessageStatus.failed)
              .length;

          notifyListeners();
        });
  }

  /// Start WhatsApp connection flow
  Future<void> connectWhatsApp() async {
    if (_academyId == null) return;

    await runBusy(() async {
      try {
        await _whatsappService?.connect(_academyId!);
        _whatsappStatus = 'qr_ready';

        _whatsappService?.connectToLiveUpdates(
          _academyId!,
          onQrReceived: (qr) {
            _qrCode = qr;
            _whatsappStatus = 'qr_ready';
            notifyListeners();
          },
          onStatusChanged: (status) {
            _whatsappStatus = status;
            if (status == 'connected') _qrCode = null;
            notifyListeners();
          },
        );
      } catch (e) {
        debugPrint('Error connecting WhatsApp: $e');
      }
    });
  }

  /// Disconnect WhatsApp
  Future<void> disconnectWhatsApp() async {
    if (_academyId == null) return;

    final confirmed = await runBusy(() async {
      return await _whatsappService?.disconnect(_academyId!) ?? false;
    });

    if (confirmed == true) {
      _whatsappStatus = 'not_initialized';
      _qrCode = null;
      notifyListeners();
    }
  }

  /// Send Single Message
  Future<bool> sendSingleMessage(
    BuildContext context, {
    required String recipient,
    required String message,
    String? studentId,
    String? studentName,
  }) async {
    if (_academyId == null) return false;

    final result = await runGuarded<bool>(
      () async {
        // 1. Send via Backend
        final success =
            await _whatsappService?.sendMessage(
              academyId: _academyId!,
              to: recipient,
              message: message,
            ) ??
            false;

        // 2. Log to Firestore
        final log = WhatsAppMessage(
          id: '',
          recipient: recipient,
          message: message,
          status: success
              ? WhatsAppMessageStatus.sent
              : WhatsAppMessageStatus.failed,
          createdAt: DateTime.now(),
          sentAt: success ? DateTime.now() : null,
          error: success ? null : 'Failed to send message',
          studentId: studentId,
          studentName: studentName,
          type: 'individual',
        );

        await _firestore
            .collection('academies')
            .doc(_academyId)
            .collection('whatsappLogs')
            .add(log.toFirestore());

        // 3. Audit Log
        await AppServices.instance.getAuditLogService.logAction(
          action: 'message_sent',
          module: 'communications',
          targetId: recipient,
        );

        return success;
      },
      context: context,
      loadingMessage: 'Sending Message...',
    );

    return result ?? false;
  }

  /// Send Bulk Messages
  Future<void> sendBulkMessages(
    BuildContext context, {
    required List<Map<String, String>>
    recipients, // [{to, message, studentId, studentName}]
    required String broadcastType,
  }) async {
    if (_academyId == null) return;

    await runGuarded(
      () async {
        final List<Map<String, String>> payload = recipients
            .map((r) => {'to': r['to']!, 'message': r['message']!})
            .toList();

        // 1. Send via Backend
        final results =
            await _whatsappService?.sendBulk(
              academyId: _academyId!,
              messages: payload,
            ) ??
            [];

        // 2. Log all results to Firestore
        final batch = _firestore.batch();
        for (var i = 0; i < recipients.length; i++) {
          final r = recipients[i];
          final res = results.firstWhere(
            (element) => element['to'] == r['to'],
            orElse: () => {'success': false},
          );

          final success = res['success'] == true;
          final log = WhatsAppMessage(
            id: '',
            recipient: r['to']!,
            message: r['message']!,
            status: success
                ? WhatsAppMessageStatus.sent
                : WhatsAppMessageStatus.failed,
            createdAt: DateTime.now(),
            sentAt: success ? DateTime.now() : null,
            error: success ? null : res['error']?.toString(),
            studentId: r['studentId'],
            studentName: r['studentName'],
            type: 'broadcast',
          );

          final docRef = _firestore
              .collection('academies')
              .doc(_academyId)
              .collection('whatsappLogs')
              .doc();
          batch.set(docRef, log.toFirestore());
        }
        await batch.commit();

        // 3. Audit Log
        await AppServices.instance.getAuditLogService.logAction(
          action: 'broadcast_sent',
          module: 'communications',
          targetId: _academyId!,
          metadata: {
            'description':
                'Bulk WhatsApp broadcast ($broadcastType) sent to ${recipients.length} recipients',
          },
        );

        return true;
      },
      context: context,
      loadingMessage: 'Sending Bulk Messages...',
    );
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    _whatsappService?.disconnectLiveUpdates();
    super.dispose();
  }
}
