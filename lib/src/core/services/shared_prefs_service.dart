import 'package:educore/src/core/services/prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService implements PrefsService {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('Prefs not initialized');
    }
    return prefs;
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _requirePrefs.getBool(key) ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _requirePrefs.setBool(key, value);
  }
}

