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
      // 0. Cleanup existing process on port 3000 (Windows only)
      if (Platform.isWindows) {
        try {
          // Find PID using port 3000
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
                // Give it a moment to release the port
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

      // 1. Check current directory (Release mode exe)
      final releaseExe = p.join(p.dirname(Platform.resolvedExecutable), 'whatsapp_backend.exe');
      
      // 2. Check development path
      final devDir = p.absolute('whatsapp_service');
      final devExe = p.join(devDir, 'whatsapp_backend.exe');
      final devJs = p.join(devDir, 'index.js');

      if (kDebugMode && await File(devJs).exists()) {
        // In debug mode, prefer node index.js to support the new ESM structure
        command = 'node';
        args = ['index.js'];
        workingDir = devDir;
        debugPrint('Starting WhatsApp Backend via Node from: $devJs');
      } else if (await File(releaseExe).exists()) {
        command = releaseExe;
        debugPrint('Starting WhatsApp Backend from: $releaseExe');
      } else if (await File(devExe).exists()) {
        command = devExe;
        debugPrint('Starting WhatsApp Backend from: $devExe');
      }

      if (command == null) {
        debugPrint('WhatsApp Backend (exe or js) not found.');
        _isStarting = false;
        return;
      }

      _process = await Process.start(
        command,
        args,
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      // Log output for debugging
      _process!.stdout.listen((data) {
        final message = String.fromCharCodes(data);
        if (kDebugMode) {
          print('WA Backend: $message');
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

  void stop() {
    _process?.kill();
    _process = null;
  }
}
