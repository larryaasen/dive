import 'dart:async';
import 'package:dive/dive.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

enum DiveOutputStreamingState { stopped, active, paused, reconnecting }

/// Signature for the state syncer.
typedef _DiveSyncer = Future<void> Function();

/// Streaming output.
class DiveOutput {
  DiveOutput();

  DiveRTMPService service;
  DiveRTMPServer server;
  String serviceUrl = '';
  String serviceKey = '';
  String serviceId = 'rtmp_common';
  String outputType = 'rtmp_output';

  final provider = StateProvider<DiveOutputStreamingState>((ref) {
    return DiveOutputStreamingState.stopped;
  }, name: 'output-provider');

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
      serviceName: service?.name ?? 'tbd',
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
    _output = null;

    // Assume the state is now stopped. However, this is making an assumption. It takes a short
    // amount of time for the output to actually be fully stopped.
    // TODO: This should be improved to use signals and other techniques to determine when the output
    // has stopped.
    DiveCore.container.read(provider.notifier).state = DiveOutputStreamingState.stopped;

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
        Timer(const Duration(seconds: 2), () {
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
    final state = DiveOutputStreamingState.values[obslib.streamOutputGetState(_output)];
    DiveCore.container.read(provider.notifier).state = state;
    if (state == DiveOutputStreamingState.stopped) {}
  }
}
