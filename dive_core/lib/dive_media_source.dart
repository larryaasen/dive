import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/dive_sources.dart';
import 'package:riverpod/riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

enum DiveMediaState {
  NONE,
  PLAYING,
  OPENING,
  BUFFERING,
  PAUSED,
  STOPPED,
  ENDED,
  ERROR,
}

class DiveMediaSourceStateNotifier extends StateNotifier<DiveMediaState> {
  DiveMediaState get mediaState => state;

  DiveMediaSourceStateNotifier(mediaState)
      : super(mediaState ?? DiveMediaState.NONE) {
    print('DiveMediaSourceStateNotifier: created');
  }

  void updateMediaState(DiveMediaState mediaState) {
    state = mediaState;
    print("updateMediaState: hasListeners=$hasListeners");
    print("new state: $state");
  }
}

class DiveMediaSource extends DiveTextureSource {
  final stateProvider =
      StateNotifierProvider<DiveMediaSourceStateNotifier>((ref) {
    return DiveMediaSourceStateNotifier(DiveMediaState.NONE);
  }, name: 'name-DiveMediaSource');

  DiveMediaSource({String name})
      : super(inputType: DiveInputType.mediaSource, name: name);

  static Future<DiveMediaSource> create(String localFile) async {
    final source = DiveMediaSource(name: 'my media');
    await source.setupController(source.trackingUUID);
    if (!await DivePlugin.createMediaSource(source.trackingUUID, localFile)) {
      return null;
    }
    source.syncState();
    return source;
  }

  /// Sync the media state from the media source to the state provider,
  /// delaying if necessary.
  Future<void> syncState({int delay = 100}) async {
    if (delay > 0) {
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
    final state = await DivePlugin.mediaGetState(trackingUUID);
    DiveCore.notifierFor(stateProvider)
        .updateMediaState(DiveMediaState.values[state]);
    return;
  }

  Future<bool> play() async {
    final rv = await DivePlugin.mediaPlayPause(trackingUUID, false);
    if (rv) {
      syncState();
    }
    return rv;
  }

  Future<bool> pause() async {
    final rv = await DivePlugin.mediaPlayPause(trackingUUID, true);
    print("pause: mediaPlayPause rv=$rv");
    if (rv) {
      syncState();
    }
    return rv;
  }

  Future<bool> stop() async {
    final rv = await DivePlugin.mediaStop(trackingUUID);
    print("stop: mediaPlayPause rv=$rv");
    if (rv) {
      syncState();
    }
    return rv;
  }
}

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
    final state = await DivePlugin.outputGetState();
    DiveCore.notifierFor(stateProvider)
        .updateOutputState(DiveOutputStreamingState.values[state]);
    return;
  }

  Future<bool> start() async {
    return DivePlugin.startStopStream(true).then((value) {
      syncState(repeating: true);
      return value;
    });
  }

  Future<bool> stop() async {
    return DivePlugin.startStopStream(false).then((value) {
      syncState(repeating: true);
      return value;
    });
  }
}
