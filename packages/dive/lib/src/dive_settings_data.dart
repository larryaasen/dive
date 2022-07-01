import 'package:dive_obslib/dive_obslib.dart';

import 'dive_settings.dart';

/// This private class should not be included in dive.dart and should not be exported for public use.
/// It is private because it includes references to obslib, which should remain private to the
/// dive package.
extension DiveSettingsObslibData on DiveSettings {
  /// Convert [DiveSettings] to [DiveObslibData].
  DiveObslibData toData() => settingsToData(this);

  /// Release the underlying data. This should be called when the settings are no longer needed.
  void dispose(DiveObslibData data) => data.dispose();

  static DiveObslibData settingsToData(DiveSettings settings) {
    final data = DiveObslibData();
    settings.settings.forEach((key, value) {
      switch (value.runtimeType) {
        case bool:
          data.setBool(key, value as bool);
          break;
        case double:
          data.setDouble(key, value as double);
          break;
        case int:
          data.setInt(key, value as int);
          break;
        case String:
          data.setString(key, value as String);
          break;
        default:
          throw UnsupportedError('invalid settings type');
      }
    });

    return data;
  }
}
