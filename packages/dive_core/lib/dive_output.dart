import 'dart:async';
import 'dart:typed_data';
import 'package:dive_core/dive_sources.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_system_log.dart';

enum DiveOutputStreamingState { stopped, active, paused, reconnecting }

class DiveOutputStateNotifier extends StateNotifier<DiveOutputStreamingState> {
  DiveOutputStreamingState get outputState => state;

  DiveOutputStateNotifier(outputState)
      : super(outputState ?? DiveOutputStreamingState.stopped);

  void updateOutputState(DiveOutputStreamingState outputState) {
    state = outputState;
  }
}

class DiveOutput {
  final String name;
  final Stream<DiveDataStreamItem> frameInput;

  DiveOutput({this.name, this.frameInput});

  String serviceUrl = 'rtmp://live-iad05.twitch.tv/app/<your_stream_key>';
  String serviceKey = '<your_stream_key>';
  String serviceId = 'rtmp_common';
  String outputType = 'rtmp_output';

  final stateProvider = StateNotifierProvider<DiveOutputStateNotifier>((ref) {
    return DiveOutputStateNotifier(DiveOutputStreamingState.stopped);
  }, name: 'name-DiveMediaSource');

  Timer _timer;

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
          _timer.cancel();
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

  bool start() {
    if (frameInput != null) {
      void onData(DiveDataStreamItem item) {
        Uint8List fileBytes = item.data;
        DiveLog.message(
            "DiveOutput.onData: ($name) output bytes count: ${fileBytes.length}");
      }

      frameInput.listen(onData);
      DiveLog.message('DiveOutput.start: ($name) started');
    }
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
