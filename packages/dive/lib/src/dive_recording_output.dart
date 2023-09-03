import 'dart:async';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod/riverpod.dart';

import 'dive_core.dart';
import 'dive_format.dart';
import 'dive_system_log.dart';

enum DiveOutputRecordingActiveState { stopped, active, paused }

class DiveOutputRecordingState extends Equatable {
  const DiveOutputRecordingState({
    this.activeState = DiveOutputRecordingActiveState.stopped,
    this.startTime,
    this.duration,
    this.folder,
  });

  final DiveOutputRecordingActiveState activeState;
  final DateTime? startTime;
  final Duration? duration;
  final String? folder;

  @override
  List<Object?> get props => [activeState, startTime, duration, folder];

  DiveOutputRecordingState copyWith({
    DiveOutputRecordingActiveState? activeState,
    DateTime? startTime,
    Duration? duration,
    String? folder,
  }) {
    return DiveOutputRecordingState(
      activeState: activeState ?? this.activeState,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      folder: folder ?? this.folder,
    );
  }
}

/// Recording output.
class DiveRecordingOutput {
  final outputType = 'ffmpeg_muxer';

  final provider = StateProvider<DiveOutputRecordingState>((ref) {
    return const DiveOutputRecordingState();
  }, name: 'output-recording-provider');

  DiveOutputRecordingState get state =>
      DiveCore.container.read(provider.notifier).state;
  set state(DiveOutputRecordingState newState) =>
      DiveCore.container.read(provider.notifier).state = newState;

  DivePointerOutput? _output;
  Timer? _updateTimer;

  @mustCallSuper
  void dispose() {
    stop();
  }

  void updateFromMap(Map<String, Object> map) {
    final newState = state.copyWith(
      folder: map['folder'] as String? ?? '',
    );
    state = newState;
  }

  Map<String, Object> toMap() {
    return {
      'folder': state.folder ?? '',
    };
  }

  /// Start recording locally at the [filePath] specified.
  /// "/Users/larry/Movies/dive1.mkv"
  /// when [appendTimeStamp] is true:
  bool start(String filePath,
      {String? filename,
      bool appendTimeStamp = false,
      String extension = 'mkv'}) {
    if (_output != null) {
      stop();
    }

    String outputPath = filePath;
    if (filename != null && appendTimeStamp) {
      final now = DateTime.now();
      final date = DiveFormat.formatterRecordingDate.format(now);
      final time = DiveFormat.formatterRecordingTime.format(now);
      final timeFilename = '$filename $date at $time.$extension';
      outputPath = path.join(filePath, timeFilename);
    }
    DiveSystemLog.message('DiveRecordingOutput.start at path: $outputPath');

    // Create recording service
    _output = obslib.recordingOutputCreate(
        path: outputPath, outputName: 'tbd', outputType: outputType);
    if (_output == null) {
      DiveSystemLog.error('DiveRecordingOutput.start output create failed');
      return false;
    }

    // Start recording.
    final rv = obslib.outputStart(_output!);
    if (rv) {
      _updateState();
      _updateTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) => _updateState());
    } else {
      DiveSystemLog.error('DiveRecordingOutput.start output start failed');
    }
    return rv;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    _cancelTimer();

    if (_output == null) return false;
    DiveSystemLog.message('DiveRecordingOutput.stop');
    obslib.outputStop(_output!);
    obslib.outputRelease(_output!);
    _output = null;

    // Assume the state is now stopped. However, this is making an assumption. It takes a short
    // amount of time for the output to actually be fully stopped.
    // TODO: This should be improved to use signals and other techniques to determine when the output
    // has stopped.
    state = const DiveOutputRecordingState();

    return true;
  }

  void _cancelTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _updateState() async {
    if (_output == null) return;
    final activeState =
        DiveOutputRecordingActiveState.values[obslib.outputGetState(_output!)];
    final currentState = state;
    var startTime = currentState.startTime;
    if (currentState.startTime == null &&
        activeState == DiveOutputRecordingActiveState.active) {
      startTime = DateTime.now();
    }
    final duration = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;
    state = DiveOutputRecordingState(
        activeState: activeState, startTime: startTime, duration: duration);
  }
}
