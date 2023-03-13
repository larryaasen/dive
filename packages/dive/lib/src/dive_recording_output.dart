import 'dart:async';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_core.dart';
import 'dive_system_log.dart';

enum DiveOutputRecordingState { stopped, active, paused }

/// Signature for the state syncer.
typedef _DiveSyncer = Future<void> Function();

/// Recording output.
class DiveRecordingOutput {
  final outputType = 'ffmpeg_muxer';

  final provider = StateProvider<DiveOutputRecordingState>((ref) {
    return DiveOutputRecordingState.stopped;
  }, name: 'output-recording-provider');

  DivePointerOutput? _output;
  Timer? _timer;

  @mustCallSuper
  void dispose() {
    _cancelTimer();
    stop();
  }

  /// Start recording locally at the [path] specified.
  /// "/Users/larry/Movies/larry1.mkv"
  bool start(String path) {
    if (_output != null) {
      stop();
    }
    DiveSystemLog.message('DiveRecordingOutput.start at path: $path');

    // Create recording service
    _output = obslib.recordingOutputCreate(path: path, outputName: 'tbd', outputType: outputType);
    if (_output == null) {
      DiveSystemLog.error('DiveRecordingOutput.start output create failed');
      return false;
    }

    // Start recording.
    final rv = obslib.outputStart(_output!);
    if (rv) {
      _syncState(_updateState, repeating: true);
    } else {
      DiveSystemLog.error('DiveRecordingOutput.start output start failed');
    }
    return rv;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    if (_output == null) return false;
    DiveSystemLog.message('DiveRecordingOutput.stop');
    obslib.outputStop(_output!);
    obslib.outputRelease(_output!);
    _output = null;

    // Assume the state is now stopped. However, this is making an assumption. It takes a short
    // amount of time for the output to actually be fully stopped.
    // TODO: This should be improved to use signals and other techniques to determine when the output
    // has stopped.
    DiveCore.container.read(provider.notifier).state = DiveOutputRecordingState.stopped;

    return true;
  }

  /// Sync the media state from the media source to the state provider,
  /// delaying if necessary.
  Future<void> _syncState(_DiveSyncer? syncer, {int delay = 100, bool repeating = false}) async {
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
    _timer!.cancel();
    _timer = null;
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _updateState() async {
    if (_output == null) return;
    final state = DiveOutputRecordingState.values[obslib.outputGetState(_output!)];
    DiveCore.container.read(provider.notifier).state = state;
    if (state == DiveOutputRecordingState.stopped) {}
  }
}
