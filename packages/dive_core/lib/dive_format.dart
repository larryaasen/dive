import 'package:intl/intl.dart';

class DiveFormat {
  static final formatterLong = DateFormat('H:mm:ss');
  static final formatterMedium = DateFormat('mm:ss');
  static final formatterShort = DateFormat('mm:ss');
  static final formatterLog = DateFormat('y/M/d H:mm:ss');
  static final formatterLogMilli = DateFormat('y/M/d H:mm:ss.S');

  /// For example, for 42 milliseconds
  ///
  /// ```dart
  /// DiveFormat.formatDuration(Duration(milliseconds: 42));
  /// ```
  /// will return '0.042'
  static String formatDuration(Duration duration) {
    final date = DateTime(0).add(duration);

    DateFormat formatter;
    if (duration.compareTo(Duration(minutes: 1)) < 0)
      formatter = formatterShort;
    else if (duration.compareTo(Duration(hours: 1)) < 0)
      formatter = formatterMedium;
    else
      formatter = formatterLong;

    String formatted = formatter.format(date);
    return formatted;
  }

  static String get formatSystemLog =>
      DiveFormat.formatterLogMilli.format(DateTime.now());
}