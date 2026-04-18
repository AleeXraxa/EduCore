class FeatureOverrides {
  final List<String> enabled;
  final List<String> disabled;

  const FeatureOverrides({this.enabled = const [], this.disabled = const []});

  factory FeatureOverrides.fromMap(Map<String, dynamic> map) {
    return FeatureOverrides(
      enabled: _listString(map['enabled']),
      disabled: _listString(map['disabled']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'enabled': enabled, 'disabled': disabled};
  }

  bool isEnabled(String key) => enabled.contains(key);
  bool isDisabled(String key) => disabled.contains(key);

  int get length => enabled.length + disabled.length;

  static List<String> _listString(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }
}
