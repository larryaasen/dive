import 'dart:async';
import 'package:dive/dive.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

enum DiveOutputStreamingState { stopped, active, paused, reconnecting }

class DiveOutputStateNotifier extends StateNotifier<DiveOutputStreamingState> {
  DiveOutputStreamingState get outputState => state;

  DiveOutputStateNotifier(outputState) : super(outputState ?? DiveOutputStreamingState.stopped);

  void updateOutputState(DiveOutputStreamingState outputState) {
    state = outputState;
  }
}

/// Signature for the state syncer.
typedef _DiveSyncer = Future<void> Function();

/// Streaming output.
class DiveOutput {
  DiveRTMPService service;
  DiveRTMPServer server;
  String serviceUrl = 'rtmp://live-iad05.twitch.tv/app/<your_stream_key>';
  String serviceKey = '<your_stream_key>';
  String serviceId = 'rtmp_common';
  String outputType = 'rtmp_output';

  final stateProvider = StateNotifierProvider<DiveOutputStateNotifier>((ref) {
    return DiveOutputStateNotifier(DiveOutputStreamingState.stopped);
  }, name: 'name-DiveMediaSource');

  DivePointerOutput _output;
  Timer _timer;

  @mustCallSuper
  void dispose() {
    _cancelTimer();
    stop();
  }

  bool start() {
    if (_output != null) {
      stop();
    }
    DiveSystemLog.message('DiveOutput.start');

    // Create streaming service
    _output = obslib.streamOutputCreate(
      serviceUrl: serviceUrl,
      serviceKey: serviceKey,
      serviceId: serviceId,
      outputType: outputType,
    );
    if (_output == null) {
      DiveSystemLog.error('DiveOutput.start failed');
      return false;
    }

    // Start streaming.
    final rv = obslib.streamOutputStart(_output);
    if (rv) {
      _syncState(_updateState, repeating: true);
    }
    return rv;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    if (_output == null) return false;
    DiveSystemLog.message('DiveOutput.stop');
    obslib.streamOutputStop(_output);
    obslib.streamOutputRelease(_output);
    _syncState(_updateState, repeating: true);
    _output = null;
    return true;
  }

  /// Sync the media state from the media source to the state provider,
  /// delaying if necessary.
  Future<void> _syncState(_DiveSyncer syncer, {int delay = 100, bool repeating = false}) async {
    if (repeating) {
      // Poll the for 2 seconds
      if (_timer == null) {
        delay = delay == 0 ? 100 : delay;
        _timer = Timer.periodic(Duration(milliseconds: delay), (timer) => _updateState());
        Timer(Duration(seconds: 2), () {
          _cancelTimer();
        });
      }
    } else if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (syncer != null) syncer();
      });
    } else {
      if (syncer != null) syncer();
    }
    return;
  }

  void _cancelTimer() {
    if (_timer == null) return;
    _timer.cancel();
    _timer = null;
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _updateState() async {
    if (_output == null) return;
    DiveCore.notifierFor(stateProvider)
        .updateOutputState(DiveOutputStreamingState.values[obslib.streamOutputGetState(_output)]);
  }
}
