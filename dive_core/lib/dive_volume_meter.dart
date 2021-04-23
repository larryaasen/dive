import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';

/// The state model for a volume meter.
class DiveVolumeMeterState {
  final int channelCount;
  final List<dynamic> inputPeak;
  final List<dynamic> magnitude;
  final List<dynamic> peak;
  final DateTime lastUpdateTime;
  final bool noSignal;

  DiveVolumeMeterState({
    this.channelCount,
    this.inputPeak,
    this.magnitude,
    this.peak,
    this.lastUpdateTime,
    this.noSignal,
  });

  DiveVolumeMeterState copyWith({
    channelCount,
    inputPeak,
    magnitude,
    peak,
    lastUpdateTime,
    noSignal,
  }) {
    return DiveVolumeMeterState(
      channelCount: channelCount ?? this.channelCount,
      inputPeak: inputPeak ?? this.inputPeak,
      magnitude: magnitude ?? this.magnitude,
      peak: peak ?? this.peak,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      noSignal: noSignal ?? this.noSignal,
    );
  }

  @override
  String toString() {
    return "DiveVolumeMeterState: channelCount=$channelCount";
  }
}

class DiveVolumeMeterStateNotifier extends StateNotifier<DiveVolumeMeterState> {
  DiveVolumeMeterState get stateModel => state;

  DiveVolumeMeterStateNotifier(DiveVolumeMeterState stateModel)
      : super(stateModel ?? DiveVolumeMeterState());

  void updateState(DiveVolumeMeterState stateModel) {
    state = stateModel;
  }
}

class DiveVolumeMeter {
  DivePointer _pointer;
  DivePointer get pointer => _pointer;
  Timer _noSignalTimer;

  final stateProvider = StateNotifierProvider<DiveVolumeMeterStateNotifier>(
      (ref) => DiveVolumeMeterStateNotifier(null));

  void dispose() {
    obslib.volumeMeterDestroy(_pointer);
    _pointer = null;
  }

  Future<DiveVolumeMeter> create({DiveSource source}) async {
    _pointer = obslib.volumeMeterCreate();
    final rv = obslib.volumeMeterAttachSource(_pointer, source.pointer);
    if (!rv) {
      dispose();
      return null;
    }

    int channelCount =
        await obslib.addVolumeMeterCallback(_pointer.address, _callback);

    DiveCore.notifierFor(stateProvider)
        .updateState(DiveVolumeMeterState(channelCount: channelCount));

    return this;
  }

  void _callback(int volumeMeterPointer, List<dynamic> magnitude,
      List<dynamic> peak, List<dynamic> inputPeak) {
    if (_pointer.toInt() != volumeMeterPointer) return;

    final currentState = DiveCore.notifierFor(stateProvider).stateModel;
    final currentTime = DateTime.now();

    // Update the state and notify
    final newState = currentState.copyWith(
      magnitude: magnitude,
      peak: peak,
      inputPeak: inputPeak,
      lastUpdateTime: currentTime,
      noSignal: false,
    );
    DiveCore.notifierFor(stateProvider).updateState(newState);

    if (_noSignalTimer != null) {
      _noSignalTimer.cancel();
    }
    _noSignalTimer = Timer(Duration(milliseconds: 500), noSignalTimeout);
  }

  void noSignalTimeout() {
    _noSignalTimer.cancel();
    _noSignalTimer = null;

    final currentState = DiveCore.notifierFor(stateProvider).stateModel;
    // Update the state and notify
    final newState = currentState.copyWith(
      noSignal: true,
    );
    DiveCore.notifierFor(stateProvider).updateState(newState);
  }
}
