import 'package:dive_obslib/dive_obslib.dart';

/// Settings that can be passed around.
class DiveSettings {
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> get settings => _settings;

  /// Sets a value for a settings name.
  /// Values can only be of type: String, int, double, bool, DiveSettings, and List<DiveSettings>.
  set<T>(String name, T value) {
    if (!_validType(value)) throw UnsupportedError('value cannot be of type ${value.runtimeType}');

    _settings[name] = value;
  }

  bool _validType(dynamic value) {
    return value is String ||
        value is int ||
        value is double ||
        value is bool ||
        value is DiveSettings ||
        value is List<DiveSettings>;
  }
}

/// This private class should not be included in dive.dart and should not be exported for public use.
/// It is private because it includes references to obslib, which should remain private to the
/// dive package.
class DiveSettingsData {
  static DiveObslibData settingsToData(DiveSettings settings) {
    final data = obslib.createData();
    settings.settings.forEach((key, value) {
      switch (value.runtimeType) {
        case bool:
          data.setBool(key, value as bool);
          print("setBool: $value");
          break;
        case double:
          data.setDouble(key, value as double);
          print("setDouble: $value");
          break;
        case int:
          data.setInt(key, value as int);
          print("setInt: $value");
          break;
        case String:
          data.setString(key, value as String);
          print("setString: $value");
          break;
        default:
          throw UnsupportedError('invalid settings type');
      }
    });

    return data;
  }
}
