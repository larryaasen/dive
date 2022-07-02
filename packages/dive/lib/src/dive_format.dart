import 'package:intl/intl.dart';

class DiveFormat {
  static final formatterLong = DateFormat('H:mm:ss');
  static final formatterMedium = DateFormat('mm:ss');
  static final formatterShort = DateFormat('mm:ss');
  static final formatterShortest = DateFormat('s.S');
  static final formatterLog = DateFormat('y/M/d H:mm:ss');

  /// For example, for 42 milliseconds
  ///
  /// ```dart
  /// DiveFormat.formatDuration(Duration(milliseconds: 42));
  /// ```
  /// will return '0.042'
  static String formatDuration(Duration duration) {
    var date = DateTime(0).add(duration);

    DateFormat formatter;
    if (duration.compareTo(const Duration(seconds: 1)) < 0) {
      formatter = formatterShortest;
    } else if (duration.compareTo(const Duration(minutes: 1)) < 0) {
      // Round the milliseconds up to the next second.
      date = date.add(const Duration(milliseconds: 500));
      formatter = formatterShort;
    } else if (duration.compareTo(const Duration(hours: 1)) < 0) {
      formatter = formatterMedium;
    } else {
      formatter = formatterLong;
    }

    String formatted = formatter.format(date);
    return formatted;
  }

  static String formatSystemLog() {
    return DiveFormat.formatterLog.format(DateTime.now());
  }
}
