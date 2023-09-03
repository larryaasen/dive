import 'dart:async';

import 'package:dive/dive.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

enum DiveOutputStreamingActiveState { stopped, active, paused, reconnecting, failed }

class DiveOutputStreamingState extends Equatable {
  const DiveOutputStreamingState({
    this.activeState = DiveOutputStreamingActiveState.stopped,
    this.startTime,
    this.duration,
  });

  final DiveOutputStreamingActiveState activeState;
  final DateTime? startTime;
  final Duration? duration;

  @override
  List<Object?> get props => [activeState, startTime, duration];

  DiveOutputStreamingState copyWith({
    DiveOutputStreamingActiveState? activeState,
    DateTime? startTime,
    Duration? duration,
  }) {
    return DiveOutputStreamingState(
      activeState: activeState ?? this.activeState,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
    );
  }
}

/// Streaming output.
class DiveStreamingOutput {
  static const defaultServiceId = 'rtmp_common';
  static const defaultOutputType = 'rtmp_output';

  DiveRTMPService? service;
  DiveRTMPServer? server;
  String serviceUrl = '';
  String serviceKey = '';
  String serviceId = defaultServiceId;
  String outputType = defaultOutputType;

  final provider = StateProvider<DiveOutputStreamingState>((ref) {
    return const DiveOutputStreamingState();
  }, name: 'output-provider');

  DiveOutputStreamingState get state => DiveCore.container.read(provider.notifier).state;

  set state(DiveOutputStreamingState newState) {
    final currentState = state;
    if (currentState != newState) {
      DiveCore.container.read(provider.notifier).state = newState;
    }
  }

  DivePointerOutput? _output;
  Timer? _timer;

  @mustCallSuper
  void dispose() {
    _cancelTimer();
    stop();
  }

  void updateFromMap(Map<String, Object?> map) {
    outputType = map['outputType'] as String? ?? '';
    outputType = outputType.isEmpty ? defaultOutputType : outputType;

    final serverName = map['server.name'] as String? ?? '';
    final serverUrl = map['server.url'] as String? ?? '';
    if (serverName.isNotEmpty && serverUrl.isNotEmpty) {
      server = DiveRTMPServer(name: serverName, url: serverUrl);
    }

    final serviceName = map['service.name'] as String? ?? '';
    service = DiveRTMPService(name: serviceName, servers: []);

    serviceId = map['serviceId'] as String? ?? '';
    serviceId = serviceId.isEmpty ? defaultServiceId : serviceId;

    serviceKey = map['serviceKey'] as String? ?? '';
    serviceUrl = map['serviceUrl'] as String? ?? '';
  }

  Map<String, Object> toMap() {
    return {
      'outputType': outputType,
      'server.name': server?.name ?? '',
      'server.url': server?.url ?? '',
      'service.name': service?.name ?? '',
      'serviceId': serviceId,
      'serviceKey': serviceKey,
      'serviceUrl': serviceUrl,
    };
  }

  bool start() {
    if (_output != null) {
      stop();
    }
    DiveSystemLog.message('DiveStreamingOutput.start');

    // Create streaming service
    _output = obslib.streamOutputCreate(
      serviceName: service?.name ?? 'tbd',
      serviceUrl: serviceUrl,
      serviceKey: serviceKey,
      serviceId: serviceId,
      outputType: outputType,
    );
    if (_output == null) {
      DiveSystemLog.error('DiveStreamingOutput.start failed');
      return false;
    }

    // Start streaming.
    final rv = obslib.outputStart(_output!);
    if (rv) {
      // _syncState(_updateActiveState, repeating: true);
      _updateActiveState(restartDuration: true);
      // Sync the media state from the media source to the state provider.
      // In the future when monitoring signals, this polling timer will not be needed.
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateActiveState());
    } else {
      state = const DiveOutputStreamingState(activeState: DiveOutputStreamingActiveState.failed);
    }
    return rv;
  }

  // Always call this method `stop` to ensure the resources are cleaned up.
  bool stop() {
    if (_output == null) return false;
    DiveSystemLog.message('DiveStreamingOutput.stop');
    obslib.outputStop(_output!);
    obslib.outputRelease(_output!);
    _output = null;

    // Assume the state is now stopped. However, this is making an assumption. It takes a short
    // amount of time for the output to actually be fully stopped.
    // TODO: This should be improved to use signals and other techniques to determine when the output
    // has stopped.
    state = state.copyWith(activeState: DiveOutputStreamingActiveState.stopped);

    _cancelTimer();

    return true;
  }

  void _cancelTimer() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _updateActiveState({bool restartDuration = false}) async {
    if (_output == null) return;
    final activeState = DiveOutputStreamingActiveState.values[obslib.outputGetState(_output!)];
    final currentState = state;
    var startTime = restartDuration ? null : currentState.startTime;
    if (startTime == null && activeState == DiveOutputStreamingActiveState.active) {
      startTime = DateTime.now();
    }
    final duration = startTime != null ? DateTime.now().difference(startTime) : Duration.zero;

    state = DiveOutputStreamingState(activeState: activeState, startTime: startTime, duration: duration);
    if (activeState == DiveOutputStreamingActiveState.stopped) {}
  }
}
