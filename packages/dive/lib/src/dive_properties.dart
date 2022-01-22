import 'dart:convert';

/// Maintains a set of property names and values.
///
/// Example:
/// ```
/// void example() {
///   final properties = DiveCoreProperties();
///   properties.setBool("file_name", true);
/// }
/// ```
class DiveCoreProperties {
  DiveCoreProperties();

  final Map<String, dynamic> _properties = {};

  /// Sets a [bool] property with the [name] to the [value].
  void setBool(String name, bool value) {
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty', 'name');
    }
    _properties[name] = value;
  }

  /// Sets a [int] property with the [name] to the [value].
  void setInt(String name, int value) {
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty', 'name');
    }
    _properties[name] = value;
  }

  /// Sets a [String] property with the [name] to the [value].
  /// The [value] can be null or empty.
  void setString(String name, String value) {
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty', 'name');
    }
    _properties[name] = value;
  }

  /// Gets a [bool] property value for the [name].
  bool? getBool(String name) => _properties[name];

  /// Gets a [int] property value for the [name].
  int? getInt(String name) => _properties[name];

  /// Gets a [String] property value for the [name].
  String? getString(String name) => _properties[name];

  /// Remove all properties.
  void removeAll() => _properties.clear();

  String toJson() => json.encode(_properties);

  factory DiveCoreProperties.fromJson(String source) =>
      DiveCoreProperties.fromMap(json.decode(source));

  factory DiveCoreProperties.fromMap(Map<String, dynamic> map) {
    final properties = DiveCoreProperties();
    for (var key in map.keys) {
      final value = map[key];
      if (value is bool) {
        properties.setBool(key, value);
      } else if (value is int) {
        properties.setInt(key, value);
      } else if (value is String) {
        properties.setString(key, value);
      }
    }
    return properties;
  }
}
