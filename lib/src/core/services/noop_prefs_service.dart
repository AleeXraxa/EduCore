import 'package:educore/src/core/services/prefs_service.dart';

class NoopPrefsService implements PrefsService {
  final Map<String, Object?> _mem = <String, Object?>{};

  @override
  Future<void> init() async {}

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = _mem[key];
    if (value is bool) return value;
    return defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _mem[key] = value;
  }
}

