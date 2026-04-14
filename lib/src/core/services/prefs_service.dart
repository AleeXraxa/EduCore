abstract class PrefsService {
  Future<void> init();

  Future<bool> getBool(
    String key, {
    bool defaultValue = false,
  });

  Future<void> setBool(String key, bool value);
}

