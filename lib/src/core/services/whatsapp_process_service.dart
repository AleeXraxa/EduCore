import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class WhatsAppProcessService {
  Process? _process;
  bool _isStarting = false;

  // Surfaces the last startup error so the UI can show it
  String? _lastError;
  String? get lastError => _lastError;

  bool get isRunning => _process != null;

  Future<void> init() async {
    if (isRunning || _isStarting) return;
    _isStarting = true;
    _lastError = null;

    try {
      // 0. Cleanup existing process on port 3000 (Windows only)
      if (Platform.isWindows) {
        try {
          final findPid = await Process.run('cmd', ['/c', 'netstat -ano | findstr :3000']);
          final output = findPid.stdout.toString().trim();

          if (output.isNotEmpty) {
            final lines = output.split('\r\n');
            for (final line in lines) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 5 && parts[1].contains(':3000')) {
                final pid = parts.last;
                debugPrint('Cleaning up stale WhatsApp process (PID: $pid) on port 3000');
                await Process.run('taskkill', ['/F', '/T', '/PID', pid]);
                await Future.delayed(const Duration(milliseconds: 500));
              }
            }
          }
        } catch (e) {
          debugPrint('Port cleanup failed (safe to ignore): $e');
        }
      }

      String? command;
      List<String> args = [];
      String? workingDir;

      final exeDir = p.dirname(Platform.resolvedExecutable);

      // Candidate paths (checked in priority order):
      // 1. Debug: whatsapp_service/index.js (node)
      // 2. Release option A: whatsapp_backend.exe next to the Flutter exe
      // 3. Release option B: whatsapp_service/whatsapp_backend.exe next to the Flutter exe
      // 4. Dev fallback: whatsapp_service/whatsapp_backend.exe relative to CWD
      final devDir = p.absolute('whatsapp_service');
      final devJs = p.join(devDir, 'index.js');
      final devExe = p.join(devDir, 'whatsapp_backend.exe');

      final releaseExeFlat = p.join(exeDir, 'whatsapp_backend.exe');
      final releaseExeSubfolder = p.join(exeDir, 'whatsapp_service', 'whatsapp_backend.exe');

      if (kDebugMode && await File(devJs).exists()) {
        command = 'node';
        args = ['index.js'];
        workingDir = devDir;
        debugPrint('[WhatsApp] Starting via Node from: $devJs');
      } else if (await File(releaseExeFlat).exists()) {
        command = releaseExeFlat;
        workingDir = exeDir;
        debugPrint('[WhatsApp] Starting from flat release: $releaseExeFlat');
      } else if (await File(releaseExeSubfolder).exists()) {
        command = releaseExeSubfolder;
        workingDir = p.join(exeDir, 'whatsapp_service');
        debugPrint('[WhatsApp] Starting from release subfolder: $releaseExeSubfolder');
      } else if (await File(devExe).exists()) {
        command = devExe;
        workingDir = devDir;
        debugPrint('[WhatsApp] Starting from dev exe: $devExe');
      }

      if (command == null) {
        _lastError =
            'WhatsApp backend not found.\n\nExpected at:\n• $releaseExeFlat\n• $releaseExeSubfolder';
        debugPrint('[WhatsApp] Backend not found. Searched:\n'
            '  1. $releaseExeFlat\n'
            '  2. $releaseExeSubfolder\n'
            '  3. $devExe');
        _isStarting = false;
        return;
      }

      _process = await Process.start(
        command,
        args,
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      _process!.stdout.listen((data) {
        final message = String.fromCharCodes(data);
        debugPrint('[WA Backend]: $message');
      });

      _process!.stderr.listen((data) {
        final message = String.fromCharCodes(data);
        debugPrint('[WA Backend Error]: $message');
      });

      _process!.exitCode.then((code) {
        debugPrint('[WhatsApp] Backend exited with code $code');
        if (code != 0) {
          _lastError = 'WhatsApp backend crashed (exit code $code). Try restarting the app.';
        }
        _process = null;
      });

      debugPrint('[WhatsApp] Backend started with PID: ${_process!.pid}');
    } catch (e) {
      _lastError = 'Failed to start WhatsApp backend: $e';
      debugPrint('[WhatsApp] $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() async {
    if (_process == null) return;

    try {
      // 1. Try graceful shutdown first
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.post('localhost', 3000, '/shutdown');
      await request.close();
      debugPrint('Graceful shutdown request sent to WhatsApp Backend.');
      
      // 2. Wait up to 5 seconds for it to exit on its own
      int count = 0;
      while (_process != null && count < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        count++;
      }
    } catch (e) {
      debugPrint('Graceful shutdown failed: $e');
    } finally {
      // 3. Force kill if still running after timeout or error
      if (_process != null) {
        debugPrint('Force killing WhatsApp Backend (PID: ${_process!.pid})');
        _process!.kill();
        _process = null;
      }
    }
  }
}
