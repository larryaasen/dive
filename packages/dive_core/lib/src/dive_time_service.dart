// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';

/// The state that is output in the stream by [DiveTimeService].
class DiveTimeState {
  const DiveTimeState(this.now, this.nowFormatted);

  final DateTime now;
  final String nowFormatted;
}

/// A wall clock time service that outputs a stream.
/// Example usage:
///
/// ```dart
/// void example() {
///   final timeService = DiveTimeService();
///   timeService.stream.listen(
///     (data) => print('Received: $data'),
///     onError: (error) => print('Error: $error'),
///     onDone: () => print('Stream closed'),
///   );
/// }
/// ```
class DiveTimeService {
  DiveTimeService() {
    _initialize();
  }

  /// Create a StreamController
  final _controller = StreamController<DiveTimeState>();

  Stream<DiveTimeState> get stream => _controller.stream;

  /// Update the state.
  void _updateState(DiveTimeState newState) {
    // Add data to stream
    _controller.sink.add(newState);
  }

  /// Initialize this service.
  void _initialize() {
    Timer.periodic(const Duration(seconds: 1), _onTimer);
  }

  /// The timer went off.
  void _onTimer(Timer timer) {
    final time = DateTime.now();
    _updateState(DiveTimeState(time, _formatted(time)));
  }

  /// Format the time into a [String].
  static String _formatted(DateTime time) {
    final hour = time.hour.toString();
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = time.second.toString().padLeft(2, '0');
    String timeOnly = '$hour:$minutes:$seconds';
    return timeOnly;
  }
}
