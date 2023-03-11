/// Settings that can be passed around.
class DiveSettings {
  final Map<String, dynamic> _settings = {};
  Map<String, dynamic> get settings => _settings;

  /// Sets a value for a settings name.
  /// Values can only be of type: String, int, double, bool, DiveSettings, and List<DiveSettings>.
  set<T>(String name, T value) {
    if (!_validType(value)) throw UnsupportedError('value cannot be of type ${value.runtimeType}');

    _settings[name] = value;
  }

  T? get<T>(String name) => _settings[name];

  bool _validType(dynamic value) {
    return value is String ||
        value is int ||
        value is double ||
        value is bool ||
        value is DiveSettings ||
        value is List<DiveSettings>;
  }
}

// class DiveSetting<T> {
//   final String name;
//   final T value;
//   const DiveSetting(this.name, this.value);
// }
// var local_file = DiveSetting<String>('local_file', localFile);
// var clear_on_media_end = DiveSetting<bool>('clear_on_media_end', true);
// var reconnect_delay_sec = DiveSetting<int>('reconnect_delay_sec', 10);
