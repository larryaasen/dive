import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

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
    DiveCore.notifierFor(stateProvider).updateOutputState(
        DiveOutputStreamingState.values[obslib.outputGetState()]);
    // final state = await DivePlugin.outputGetState();
    // DiveCore.notifierFor(stateProvider)
    //     .updateOutputState(DiveOutputStreamingState.values[state]);
  }

  Future<bool> start() async {
    final rv = obslib.streamOutputStart();
    syncState(repeating: true);
    return rv;
    // return DivePlugin.startStopStream(true).then((value) {
    //   syncState(repeating: true);
    //   return value;
    // });
  }

  Future<bool> stop() async {
    obslib.streamOutputStop();
    syncState(repeating: true);
    return true;
    // return DivePlugin.startStopStream(false).then((value) {
    //   syncState(repeating: true);
    //   return value;
    // });
  }
}
