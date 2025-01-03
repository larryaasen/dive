// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';
import 'dart:core';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_core.dart';
import 'dive_sources.dart';

/// The state model for an audio meter.
class DiveAudioMeterState extends Equatable {
  const DiveAudioMeterState({
    this.channelCount = 0,
    this.inputPeak,
    this.inputPeakHold,
    this.magnitude,
    this.magnitudeAttacked,
    this.peak,
    this.peakDecayed,
    this.peakHold,
    this.inputpPeakHoldLastUpdateTime,
    this.peakHoldLastUpdateTime,
    this.lastUpdateTime,
    this.noSignal = false,
  });

  /// channel count: there can be many audio channels in an audio source, such as left and right.
  final int channelCount;

  /// input peak - original
  final List<dynamic>? inputPeak;

  /// input peak hold - derived
  final List<dynamic>? inputPeakHold;

  /// magnitude - original
  final List<dynamic>? magnitude;

  /// magnitude attacked - derived
  final List<dynamic>? magnitudeAttacked;

  /// peak - original
  final List<dynamic>? peak;

  /// peak decayed - derived
  final List<dynamic>? peakDecayed;

  /// peak and hold - derived
  final List<dynamic>? peakHold;

  /// input peak and hold last update time
  final List<DateTime>? inputpPeakHoldLastUpdateTime;

  /// peak and hold last update time
  final List<DateTime>? peakHoldLastUpdateTime;

  /// last update time
  final DateTime? lastUpdateTime;

  /// no signal
  final bool noSignal;

  DiveAudioMeterState copyWith({
    channelCount,
    inputPeak,
    inputPeakHold,
    magnitude,
    magnitudeAttacked,
    peak,
    peakDecayed,
    peakHold,
    inputpPeakHoldLastUpdateTime,
    peakHoldLastUpdateTime,
    lastUpdateTime,
    noSignal,
  }) {
    return DiveAudioMeterState(
      channelCount: channelCount ?? this.channelCount,
      inputPeak: inputPeak ?? this.inputPeak,
      inputPeakHold: inputPeakHold ?? this.inputPeakHold,
      magnitude: magnitude ?? this.magnitude,
      magnitudeAttacked: magnitudeAttacked ?? this.magnitudeAttacked,
      peak: peak ?? this.peak,
      peakDecayed: peakDecayed ?? this.peakDecayed,
      peakHold: peakHold ?? this.peakHold,
      inputpPeakHoldLastUpdateTime:
          inputpPeakHoldLastUpdateTime ?? this.inputpPeakHoldLastUpdateTime,
      peakHoldLastUpdateTime:
          peakHoldLastUpdateTime ?? this.peakHoldLastUpdateTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      noSignal: noSignal ?? this.noSignal,
    );
  }

  @override
  List<Object?> get props => [
        channelCount,
        inputPeak,
        inputPeakHold,
        magnitude,
        magnitudeAttacked,
        peak,
        peakDecayed,
        peakHold,
        inputpPeakHoldLastUpdateTime,
        peakHoldLastUpdateTime,
        lastUpdateTime,
        noSignal,
      ];
}

/// A class for the audio meter data and processing.
class DiveAudioMeterSource {
  final DivePointer pointer;

  DiveAudioMeterSource(this.pointer);

  /// Audio meter minumum level (dB)
  static const double audioMinLevel = DiveBaseObslib.audioMinLevel;

  static const initialLevel = -10000.0; // dB
  static const peakHoldDuration = 20.0; //  seconds
  static const inputPeakHoldDuration = 1.0; // seconds

  Timer? _noSignalTimer;
  Stopwatch? _stopwatch;

  /// A Riverpod [StateProvider] that provides [DiveAudioMeterState] state updates.
  final provider =
      StateProvider<DiveAudioMeterState>((ref) => const DiveAudioMeterState());

  void dispose() {
    destroy(pointer);
    _noSignalTimer?.cancel();
  }

  static void destroy(DivePointer pointer) {
    obslib.volumeMeterDestroy(pointer);
    pointer.releasePointer();
  }

  /// Creat an audio meter for a [source].
  static Future<DiveAudioMeterSource?> create(
      {required DiveSource source}) async {
    final sourcePointer = source.pointer;
    if (sourcePointer == null || sourcePointer.isNull) return null;

    final pointer = obslib.volumeMeterCreate();
    if (pointer.isNull) return null;

    final rv = obslib.volumeMeterAttachSource(pointer, sourcePointer);
    if (!rv) {
      print("DiveAudioMeterSource.create: volumeMeterAttachSource failed");
      destroy(pointer);
      return null;
    }

    final volumeMeter = DiveAudioMeterSource(pointer);
    await volumeMeter.initialize();
    return volumeMeter;
  }

  Future<void> initialize() async {
    int channelCount =
        await obslib.addVolumeMeterCallback(pointer.address, _onMeterUpdated);

    DiveCore.container.read(provider.notifier).state =
        _clearDerived(DiveAudioMeterState(channelCount: channelCount));
  }

  /// Called when the volume meter is updated.
  void _onMeterUpdated(int volumeMeterPointer, List<double> magnitude,
      List<double> peak, List<double> inputPeak) {
    assert(magnitude.length == peak.length && peak.length == inputPeak.length);
    if (pointer.toInt() != volumeMeterPointer) return;

    // Determine the elapsed time since the last update (seconds)
    double elapsedTime;
    if (_stopwatch == null) {
      _stopwatch = Stopwatch()..start();
      elapsedTime = 0.0;
    } else {
      elapsedTime = _stopwatch!.elapsedMilliseconds / 1000.0;
      _stopwatch?.reset();
    }

    final now = DateTime.now();

    // Get the current state
    final currentState = DiveCore.container.read(provider.notifier).state;

    // Determine the attack of audio since last update (seconds).
    double attackRate = 0.99;
    double attack = (elapsedTime / 0.3) * attackRate;

    // Determine decay of audio since last update (seconds).
    double peakDecayRate = 20.0 / 1.7;
    final peakDecay = peakDecayRate * elapsedTime;

    final inputPeakHold = currentState.inputPeakHold;
    final magnitudeAttacked = currentState.magnitudeAttacked;
    final peakDecayed = currentState.peakDecayed;
    final peakHold = currentState.peakHold;
    final inputPeakHoldLastUpdateTime =
        currentState.inputpPeakHoldLastUpdateTime;
    final peakHoldLastUpdateTime = currentState.peakHoldLastUpdateTime;

    // For each channel
    for (var channel = 0; channel < currentState.channelCount; channel++) {
      // Magnitude attacked
      if (magnitude[channel].isInfinite) {
      } else if (magnitudeAttacked![channel] == initialLevel) {
        magnitudeAttacked[channel] = magnitude[channel];
      } else {
        final value =
            (magnitude[channel] - magnitudeAttacked[channel]) * attack;
        try {
          magnitudeAttacked[channel] = clamp(magnitudeAttacked[channel] + value,
              DiveBaseObslib.audioMinLevel, 0.0);
        } catch (e) {
          print("DiveAudioMeterSource._onMeterUpdated: exception 1: $e\n"
              "range ${DiveBaseObslib.audioMinLevel}, 0.0\n"
              "values ${magnitudeAttacked[channel]} + value");
        }
      }

      // Input peak hold
      if (inputPeak[channel].isInfinite) {
      } else if (inputPeak[channel] >= inputPeakHold![channel]) {
        inputPeakHold[channel] = inputPeak[channel];
        inputPeakHoldLastUpdateTime![channel] = now;
      } else {
        final timeSinceLast =
            now.difference(inputPeakHoldLastUpdateTime![channel]);
        if (timeSinceLast.inSeconds >= inputPeakHoldDuration) {
          inputPeakHold[channel] = inputPeak[channel];
          inputPeakHoldLastUpdateTime[channel] = now;
        }
      }

      // Peak decayed
      if (peak[channel].isInfinite) {
      } else if (peak[channel] >= peakDecayed![channel]) {
        peakDecayed[channel] = peak[channel];
      } else {
        try {
          peakDecayed[channel] =
              clamp(peakDecayed[channel] - peakDecay, peak[channel], 0.0);
        } catch (e) {
          print("DiveAudioMeterSource._onMeterUpdated: exception 2: $e\n"
              "range ${peak[channel]}, 0.0\n"
              "values ${peakDecayed[channel]}, $peakDecay");
        }
      }

      // Peak hold
      if (peak[channel].isInfinite) {
      } else if (peak[channel] >= peakHold![channel]) {
        peakHold[channel] = peak[channel];
        peakHoldLastUpdateTime![channel] = now;
      } else {
        final timeSinceLast = now.difference(peakHoldLastUpdateTime![channel]);
        if (timeSinceLast.inSeconds >= peakHoldDuration) {
          peakHold[channel] = peak[channel];
          peakHoldLastUpdateTime[channel] = now;
        }
      }
    }

    // Update the state and notify
    final newState = currentState.copyWith(
      inputPeak: inputPeak,
      inputPeakHold: inputPeakHold,
      magnitude: magnitude,
      magnitudeAttacked: magnitudeAttacked,
      peak: peak,
      peakDecayed: peakDecayed,
      peakHold: peakHold,
      inputpPeakHoldLastUpdateTime: inputPeakHoldLastUpdateTime,
      peakHoldLastUpdateTime: peakHoldLastUpdateTime,
      lastUpdateTime: now,
      noSignal: false,
    );

    if (currentState == newState) {
      print('Why are these states the same?');
    }
    DiveCore.container.read(provider.notifier).state = newState;

    _startNoSignalTimer();
  }

  /// Returns this num clamped to be in the range [lowerLimit]-[uppperLimit].
  /// This method ensures lowerLimit is not greater than upperLimit.
  num clamp(num value, num lowerLimit, num upperLimit) {
    if (lowerLimit > upperLimit) lowerLimit = upperLimit;
    return value.clamp(lowerLimit, upperLimit);
  }

  /// Start the no signal timer
  void _startNoSignalTimer() {
    _noSignalTimer?.cancel();
    _noSignalTimer = Timer(const Duration(milliseconds: 500), _noSignalTimeout);
  }

  void _noSignalTimeout() {
    _noSignalTimer?.cancel();
    _noSignalTimer = null;

    final currentState = DiveCore.container.read(provider.notifier).state;

    // Update the state and notify
    final newState = _clearDerived(currentState);
    DiveCore.container.read(provider.notifier).state = newState;
  }

  DiveAudioMeterState _clearDerived(DiveAudioMeterState state) =>
      state.copyWith(
        noSignal: true,
        inputPeakHold: List.filled(state.channelCount, initialLevel),
        magnitudeAttacked: List.filled(state.channelCount, initialLevel),
        peakDecayed: List.filled(state.channelCount, initialLevel),
        peakHold: List.filled(state.channelCount, initialLevel),
        inputpPeakHoldLastUpdateTime:
            List.filled(state.channelCount, DateTime.now()),
        peakHoldLastUpdateTime: List.filled(state.channelCount, DateTime.now()),
      );

  @override
  String toString() {
    return "DiveAudioMeterSource: pointer: ${pointer.address}";
  }
}
