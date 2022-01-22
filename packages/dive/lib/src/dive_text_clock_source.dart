import 'dart:async';

import 'dive_input_type.dart';
import 'dive_properties.dart';
import 'dive_source.dart';
import 'dive_stream.dart';
import 'dive_system_log.dart';

/// A text clock source that generates a stream of text strings representing
/// the current time.
class DiveTextClockSource extends DiveSource {
  static const _defaultTimerResolution = 1000; // msec

  /// The timer resolution in msec.
  static const String propertyTimerResolution = 'timer_resolution';

  @override
  DiveStream get frameOutput => _outputController.stream;

  final _outputController = StreamController<DiveDataStreamItem>.broadcast();

  DiveTextClockSource._({String? name, DiveCoreProperties? properties})
      : super(
            inputType: DiveInputType.text, name: name, properties: properties) {
    int timeout = _defaultTimerResolution;
    if (properties != null) {
      final resolution = properties.getInt(propertyTimerResolution);
      timeout = resolution ?? timeout;
    }
    startTimer(timeout);
  }

  /// Create a text source.
  factory DiveTextClockSource.create(
      {String? name, DiveCoreProperties? properties}) {
    final source = DiveTextClockSource._(name: name, properties: properties);
    return source;
  }

  Timer startTimer(int milliseconds) {
    return Timer.periodic(Duration(milliseconds: milliseconds), handleTimer);
  }

  void handleTimer(Timer timer) {
    final time = DateTime.now().toString();
    final newItem =
        DiveDataStreamItem(text: time, type: DiveSourceOutputType.text);
    _outputController.add(newItem);
    // DiveLog.message("time $time");
  }
}
