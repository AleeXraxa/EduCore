import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class WhatsAppProcessService {
  Process? _process;
  bool _isStarting = false;

  bool get isRunning => _process != null;

  Future<void> init() async {
    if (isRunning || _isStarting) return;
    _isStarting = true;

    try {
      final exePath = await _getExecutablePath();
      if (exePath == null) {
        debugPrint('WhatsApp Backend executable not found.');
        _isStarting = false;
        return;
      }

      debugPrint('Starting WhatsApp Backend from: $exePath');
      
      _process = await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.normal,
      );

      // Log output for debugging
      _process!.stdout.listen((data) {
        if (kDebugMode) {
          print('WA Backend: ${String.fromCharCodes(data)}');
        }
      });

      _process!.stderr.listen((data) {
        print('WA Backend Error: ${String.fromCharCodes(data)}');
      });

      _process!.exitCode.then((code) {
        debugPrint('WhatsApp Backend exited with code $code');
        _process = null;
      });

      debugPrint('WhatsApp Backend started with PID: ${_process!.pid}');
    } catch (e) {
      debugPrint('Failed to start WhatsApp Backend: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<String?> _getExecutablePath() async {
    // 1. Check current directory (Release mode)
    final releasePath = p.join(p.dirname(Platform.resolvedExecutable), 'whatsapp_backend.exe');
    if (await File(releasePath).exists()) return releasePath;

    // 2. Check development path
    if (kDebugMode) {
      final devPath = p.absolute('whatsapp_service', 'whatsapp_backend.exe');
      if (await File(devPath).exists()) return devPath;
    }

    return null;
  }

  void stop() {
    _process?.kill();
    _process = null;
  }
}
