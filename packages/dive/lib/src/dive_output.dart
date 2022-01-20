import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod/riverpod.dart';

import 'dive_stream.dart';
import 'dive_system_log.dart';
import 'dive_tracking.dart';

enum DiveOutputStreamingState { stopped, active, paused, reconnecting }

class DiveOutputStateNotifier extends StateNotifier<DiveOutputStreamingState> {
  DiveOutputStreamingState get outputState => state;

  DiveOutputStateNotifier(outputState)
      : super(outputState ?? DiveOutputStreamingState.stopped);

  void updateOutputState(DiveOutputStreamingState outputState) {
    state = outputState;
  }
}

/// DiveOutput: A [DiveOutput] producues an output, such as a recording or
/// livestream, from an input stream of frames.
abstract class DiveOutput extends DiveNamedTracking {
  final DiveStream frameInput;

  DiveOutput({String? name, required this.frameInput}) : super(name: name);

  /// Start the output.
  bool start();
}

class DiveOutputLogger extends DiveOutput {
  DiveOutputLogger({String? name, required DiveStream frameInput})
      : super(name: name, frameInput: frameInput);

  /// Start the output.
  @override
  bool start() {
    void onData(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        final fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveOutputLogger.onData: ($name) output bytes count: ${fileBytes.length}");
      }
    }

    void onError(error) {
      DiveLog.message('DiveOutputLogger.onError: ($name) $error');
    }

    frameInput.listen(onData, onError: onError);
    DiveLog.message('DiveOutputLogger.start: ($name) started');
    return false;
  }
}

class DiveOutputRecorder extends DiveOutput {
  DiveOutputRecorder({String? name, required DiveStream frameInput})
      : super(name: name, frameInput: frameInput);

  /// Start the output.
  @override
  bool start() {
    // TODO: implement start
    throw UnimplementedError();
  }
}

class DiveOutputStreamer extends DiveOutput {
  DiveOutputStreamer({String? name, required DiveStream frameInput})
      : super(name: name, frameInput: frameInput);

  String serviceUrl = 'rtmp://live-iad05.twitch.tv/app/<your_stream_key>';
  String serviceKey = '<your_stream_key>';
  String serviceId = 'rtmp_common';
  String outputType = 'rtmp_output';

  final stateProvider = StateNotifierProvider<DiveOutputStateNotifier>((ref) {
    return DiveOutputStateNotifier(DiveOutputStreamingState.stopped);
  }, name: 'name-DiveMediaSource');

  Timer? _timer;

  /// Sync the media state from the media source to the state provider,
  /// delaying if necessary.
  Future<void> syncState({int delay = 100, bool repeating = false}) async {
    if (repeating) {
      // Poll the for 2 seconds
      if (_timer == null) {
        delay = delay == 0 ? 100 : delay;
        _timer = Timer.periodic(
            Duration(milliseconds: delay), (timer) => _syncState());
        Timer(Duration(seconds: 2), () {
          _timer!.cancel();
          _timer = null;
        });
      }
    } else if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () {
        _syncState();
      });
    } else {
      _syncState();
    }
    return;
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _syncState() async {
    // DiveCore.notifierFor(stateProvider).updateOutputState(
    //     DiveOutputStreamingState.values[oldlib.outputGetState()]);
  }

  /// Start the output.
  @override
  bool start() {
    void onData(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        final fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveOutputStreamer.onData: ($name) output bytes count: ${fileBytes.length}");
      }
    }

    frameInput.listen(onData);
    DiveLog.message('DiveOutputStreamer.start: ($name) started');
    // // Create streaming service
    // bool rv = oldlib.streamOutputCreate(
    //   serviceUrl: serviceUrl,
    //   serviceKey: serviceKey,
    //   serviceId: serviceId,
    //   outputType: outputType,
    // );
    // if (!rv) return false;

    // // Start streaming.
    // rv = oldlib.streamOutputStart();
    // if (rv) {
    //   syncState(repeating: true);
    // }
    // return rv;
    return false;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    // oldlib.streamOutputStop();
    // oldlib.streamOutputRelease();
    // syncState(repeating: true);
    // return true;
    return false;
  }
}
