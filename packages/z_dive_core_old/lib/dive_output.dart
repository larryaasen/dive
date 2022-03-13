import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';

enum DiveOutputStreamingState { stopped, active, paused, reconnecting }

class DiveOutputStateNotifier extends StateNotifier<DiveOutputStreamingState> {
  DiveOutputStreamingState get outputState => state;

  DiveOutputStateNotifier(outputState) : super(outputState ?? DiveOutputStreamingState.stopped);

  void updateOutputState(DiveOutputStreamingState outputState) {
    state = outputState;
  }
}

class DiveOutput {
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
        _timer = Timer.periodic(Duration(milliseconds: delay), (timer) => _syncState());
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
    DiveCore.notifierFor(stateProvider)
        .updateOutputState(DiveOutputStreamingState.values[obslib.outputGetState()]);
  }

  bool start() {
    // Create streaming service
    bool rv = obslib.streamOutputCreate(
      serviceUrl: serviceUrl,
      serviceKey: serviceKey,
      serviceId: serviceId,
      outputType: outputType,
    );
    if (!rv) return false;

    // Start streaming.
    rv = obslib.streamOutputStart();
    if (rv) {
      syncState(repeating: true);
    }
    return rv;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    obslib.streamOutputStop();
    obslib.streamOutputRelease();
    syncState(repeating: true);
    return true;
  }
}
