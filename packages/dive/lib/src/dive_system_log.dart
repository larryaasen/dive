import 'dive_format.dart';

/// Example:
/// ```
/// DiveLog.message('DiveOutput.onData: output started.');
/// ```
class DiveLog {
  static void message(String message, {String group = ''}) {
    _output(message, group);
  }

  static void error(String message, {String group = ''}) {
    _output(message, group);
  }

  /// Determine the time it takes for an action to execute.
  static T timeIt<T>(String title, T Function() action,
      {bool enableTiming = true}) {
    if (!enableTiming) return action();
    final stopwatch = Stopwatch()..start();
    final result = action();
    final elapsed = stopwatch.elapsed;
    message('$title elapsed: ${elapsed.inMilliseconds}ms');
    return result;
  }

  static void _output(String message, String group) {
    final groupMsg = group.isEmpty ? '' : " [$group]";
    final timeMsg = DiveFormat.formatSystemLog;
    print("$timeMsg$groupMsg $message");
  }
}

/*
Log these itesm:
- app launch folder
- dive_core version
- dive_ui version
- app version
- device total memory size
- detected devices
- frame rate, size, etc.

11222020 11:01:49.371 [dive_core] version 1.0.1
11222020 11:01:49.371 [dive_ui] version 1.3.1
11222020 11:01:49.371 [dive_core] avail=3496.62 MB, used=599.38 MB, total=4096.00 MB

*/
