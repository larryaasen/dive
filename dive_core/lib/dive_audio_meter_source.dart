import 'dart:async';
import 'dart:core';
import 'package:dive_core/dive_core.dart';
import 'package:riverpod/riverpod.dart';

/// Signature of VolumeMeter callback.
typedef DiveVolumeMeterCallback = void Function(int volumeMeterPointer,
    List<double> magnitude, List<double> peak, List<double> inputPeak);

// TODO: figure out proper names for audio and volume meters.

// TODO: Implement this volume meter.
class DiveCoreVolumeMeter {}

// TODO: Implement this audio meter.
class DiveCoreAudioMeters {
  /// Audio meter minumum level (dB)
  static const double audioMinLevel = -60.0;

  /// Create a volume meter.
  static DiveCoreVolumeMeter volumeMeterCreate() {
    // final volmeter = _lib.old_volmeter_create(faderType);
    return DiveCoreVolumeMeter();
  }

  /// Destroy a volume meter.
  static void volumeMeterDestroy(DiveCoreVolumeMeter volumeMeter) {
    // _lib.old_volmeter_destroy(volumeMeter.pointer);
  }

  /// Attache a source to a volume meter.
  static bool volumeMeterAttachSource(
      DiveCoreVolumeMeter volumeMeter, dynamic source) {
    // final rv =
    //     _lib.old_volmeter_attach_source(volumeMeter.pointer, source.pointer);
    // return rv == 1;
    return false;
  }

  static int addVolumeMeterCallback(
      DiveCoreVolumeMeter volumeMeter, DiveVolumeMeterCallback callback) {
    return 0;
  }
}

/// The state model for an audio meter.
class DiveAudioMeterState {
  /// channel count
  final int channelCount;

  /// input peak - original
  final List<dynamic> inputPeak;

  /// input peak hold - derived
  final List<dynamic> inputPeakHold;

  /// magnitude - original
  final List<dynamic> magnitude;

  /// magnitude attacked - derived
  final List<dynamic> magnitudeAttacked;

  /// peak - original
  final List<dynamic> peak;

  /// peak decayed - derived
  final List<dynamic> peakDecayed;

  /// peak and hold - derived
  final List<dynamic> peakHold;

  /// input peak and hold last update time
  final List<DateTime> inputpPeakHoldLastUpdateTime;

  /// peak and hold last update time
  final List<DateTime> peakHoldLastUpdateTime;

  /// last update time
  final DateTime lastUpdateTime;

  /// no signal
  final bool noSignal;

  DiveAudioMeterState({
    this.channelCount,
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
    this.noSignal,
  });

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
  String toString() {
    return "DiveAudioMeterState: channelCount=$channelCount";
  }
}

class DiveAudioMeterStateNotifier extends StateNotifier<DiveAudioMeterState> {
  DiveAudioMeterState get stateModel => state;

  DiveAudioMeterStateNotifier(DiveAudioMeterState stateModel)
      : super(stateModel ?? DiveAudioMeterState());

  void updateState(DiveAudioMeterState stateModel) {
    state = stateModel;
  }
}

/// A class for the audio meter data and processing.
class DiveAudioMeterSource {
  /// Audio meter minumum level (dB)
  static const double audioMinLevel = DiveCoreAudioMeters.audioMinLevel;

  static const initialLevel = -10000.0; // dB
  static const peakHoldDuration = 20.0; //  seconds
  static const inputPeakHoldDuration = 1.0; // seconds

  DiveCoreVolumeMeter _pointer;
  DiveCoreVolumeMeter get pointer => _pointer;
  Timer _noSignalTimer;
  Stopwatch _stopwatch;

  final stateProvider = StateNotifierProvider<DiveAudioMeterStateNotifier>(
      (ref) => DiveAudioMeterStateNotifier(null));

  void dispose() {
    DiveCoreAudioMeters.volumeMeterDestroy(_pointer);
    _pointer = null;
    if (_noSignalTimer != null) {
      _noSignalTimer.cancel();
    }
  }

  Future<DiveAudioMeterSource> create({DiveSource source}) async {
    _pointer = DiveCoreAudioMeters.volumeMeterCreate();
    final rv =
        DiveCoreAudioMeters.volumeMeterAttachSource(_pointer, source.pointer);
    if (!rv) {
      print("DiveAudioMeterSource.create: volumeMeterAttachSource failed");
      dispose();
      return null;
    }

    int channelCount =
        DiveCoreAudioMeters.addVolumeMeterCallback(_pointer, _onMeterUpdated);

    DiveCore.notifierFor(stateProvider).updateState(
        _clearDerived(DiveAudioMeterState(channelCount: channelCount)));
    return this;
  }

  /// Called when the volume meter is updated.
  void _onMeterUpdated(int volumeMeterPointer, List<double> magnitude,
      List<double> peak, List<double> inputPeak) {
    assert(magnitude.length == peak.length && peak.length == inputPeak.length);
    // if (_pointer.toInt() != volumeMeterPointer) return;

    // Determine the elapsed time since the last update (seconds)
    double elapsedTime;
    if (_stopwatch == null) {
      _stopwatch = Stopwatch()..start();
      elapsedTime = 0.0;
    } else {
      elapsedTime = _stopwatch.elapsedMilliseconds / 1000.0;
      _stopwatch..reset();
    }

    final now = DateTime.now();

    // Get the current state
    var currentState = DiveCore.notifierFor(stateProvider).stateModel;

    // Determine the attack of audio since last update (seconds).
    final attackRate = 0.99;
    final attack = (elapsedTime / 0.3) * attackRate;

    // Determine decay of audio since last update (seconds).
    const double peakDecayRate = 20.0 / 1.7;
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
      } else if (magnitudeAttacked[channel] == initialLevel) {
        magnitudeAttacked[channel] = magnitude[channel];
      } else {
        final value =
            (magnitude[channel] - magnitudeAttacked[channel]) * attack;
        try {
          magnitudeAttacked[channel] = clamp(magnitudeAttacked[channel] + value,
              DiveCoreAudioMeters.audioMinLevel, 0.0);
        } catch (e) {
          print("DiveAudioMeterSource._onMeterUpdated: exception 1: $e\n"
              "range ${DiveCoreAudioMeters.audioMinLevel}, 0.0\n"
              "values ${magnitudeAttacked[channel]} + value");
        }
      }

      // Input peak hold
      if (inputPeak[channel].isInfinite) {
      } else if (inputPeak[channel] >= inputPeakHold[channel]) {
        inputPeakHold[channel] = inputPeak[channel];
        inputPeakHoldLastUpdateTime[channel] = now;
      } else {
        final timeSinceLast =
            now.difference(inputPeakHoldLastUpdateTime[channel]);
        if (timeSinceLast.inSeconds >= inputPeakHoldDuration) {
          inputPeakHold[channel] = inputPeak[channel];
          inputPeakHoldLastUpdateTime[channel] = now;
        }
      }

      // Peak decayed
      if (peak[channel].isInfinite) {
      } else if (peak[channel] >= peakDecayed[channel]) {
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
      } else if (peak[channel] >= peakHold[channel]) {
        peakHold[channel] = peak[channel];
        peakHoldLastUpdateTime[channel] = now;
      } else {
        final timeSinceLast = now.difference(peakHoldLastUpdateTime[channel]);
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
    DiveCore.notifierFor(stateProvider).updateState(newState);

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
    if (_noSignalTimer != null) {
      _noSignalTimer.cancel();
    }
    _noSignalTimer = Timer(Duration(milliseconds: 500), _noSignalTimeout);
  }

  void _noSignalTimeout() {
    _noSignalTimer.cancel();
    _noSignalTimer = null;

    var currentState = DiveCore.notifierFor(stateProvider).stateModel;

    // Update the state and notify
    final newState = _clearDerived(currentState);
    DiveCore.notifierFor(stateProvider).updateState(newState);
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
    return "DiveAudioMeterSource: pointer: ${pointer}";
  }
}
