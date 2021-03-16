import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

/// The media playback states.
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

/// The state model for a media source.
class DiveMediaSourceState {
  /// The current playback time.
  final int currentTime;

  /// The full duration of the media playback time, in milliseconds.
  final int duration;

  /// The current media playback state.
  final DiveMediaState mediaState;

  DiveMediaSourceState(
      {this.currentTime = 0,
      this.duration = 0,
      this.mediaState = DiveMediaState.NONE});

  @override
  String toString() {
    return "DiveMediaSourceState: time=$currentTime, duration=$duration, mediaState=$mediaState";
  }
}

class DiveMediaSourceStateNotifier extends StateNotifier<DiveMediaSourceState> {
  DiveMediaSourceState get stateModel => state;

  DiveMediaSourceStateNotifier(DiveMediaSourceState stateModel)
      : super(stateModel ?? DiveMediaSourceState());

  void updateMediaState(DiveMediaSourceState stateModel) {
    state = stateModel;
  }
}

class DiveMediaSource extends DiveTextureSource {
  final stateProvider = StateNotifierProvider<DiveMediaSourceStateNotifier>(
      (ref) => DiveMediaSourceStateNotifier(null));

  Timer _playbackTimer;

  final String localFile;

  DiveMediaSource({String name, this.localFile})
      : super(inputType: DiveInputType.mediaSource, name: name) {
    _playbackTimer =
        Timer.periodic(Duration(milliseconds: 1000), timerCallback);
  }

  static Future<DiveMediaSource> create(String localFile) async {
    final source = DiveMediaSource(name: 'my media', localFile: localFile);
    await source.setupController(source.trackingUUID);
    source.bridgePointer =
        obslib.createMediaSource(source.trackingUUID, localFile);
    // if (!await DivePlugin.createMediaSource(source.trackingUUID, localFile)) {
    //   return null;
    // }
    await source.syncState();
    return source.bridgePointer == null ? null : source;
  }

  /// Remove this media source.
  bool remove() {
    // TODO: finish the remove() function.
    _playbackTimer.cancel();
    _playbackTimer = null;
    return true;
  }

  void timerCallback(Timer timer) {
    if (DiveCore.notifierFor(stateProvider).stateModel.mediaState ==
        DiveMediaState.PLAYING) {
      _syncState();
    }
  }

  /// Sync the media state from the media source to the state provider,
  /// delaying if necessary.
  Future<void> syncState({int delay = 100}) {
    if (delay > 0) {
      return Future.delayed(Duration(milliseconds: delay), () {
        return _syncState();
      });
    } else {
      return _syncState();
    }
  }

  /// Sync the media state from the media source to the state provider.
  Future<void> _syncState() async {
    final state = await getState();
    DiveCore.notifierFor(stateProvider).updateMediaState(state);
    return;
  }

  /// Get the media source state for this media source.
  Future<DiveMediaSourceState> getState() async {
    final mediaState = obslib.mediaSourceGetState(bridgePointer);
    final duration = obslib.mediaSourceGetDuration(bridgePointer);
    final ms = obslib.mediaSourceGetTime(bridgePointer);
    return DiveMediaSourceState(
        currentTime: ms,
        duration: duration,
        mediaState: DiveMediaState.values[mediaState]);
    // return DivePlugin.mediaGetState(trackingUUID).then((mediaState) =>
    //     DivePlugin.mediaGetDuration(trackingUUID).then((duration) =>
    //         DivePlugin.mediaGetTime(trackingUUID).then((ms) =>
    //             DiveMediaSourceState(
    //                 currentTime: ms,
    //                 duration: duration,
    //                 mediaState: DiveMediaState.values[mediaState]))));
  }

  Future<bool> play() async {
    obslib.mediaSourcePlayPause(bridgePointer, false);
    await syncState();
    return true;
    // final rv = await DivePlugin.mediaPlayPause(trackingUUID, false);
    // if (rv) {
    //   await syncState();
    // }
    // return rv;
  }

  Future<bool> pause() async {
    obslib.mediaSourcePlayPause(bridgePointer, true);
    await syncState();
    return true;
    // final rv = await DivePlugin.mediaPlayPause(trackingUUID, true);
    // if (rv) {
    //   await syncState();
    // }
    // return rv;
  }

  Future<bool> restart() async {
    obslib.mediaSourceRestart(bridgePointer);
    await syncState();
    return true;
    // final rv = await DivePlugin.mediaRestart(trackingUUID);
    // if (rv) {
    //   await syncState();
    // }
    // return rv;
  }

  Future<bool> stop() async {
    obslib.mediaSourceStop(bridgePointer);
    await syncState();
    return true;
    // final rv = await DivePlugin.mediaStop(trackingUUID);
    // if (rv) {
    //   await syncState();
    // }
    // return rv;
  }

  Future<int> getDuration() async {
    return obslib.mediaSourceGetDuration(bridgePointer);
    // return DivePlugin.mediaGetDuration(trackingUUID);
  }

  Future<int> getTime() async {
    return obslib.mediaSourceGetTime(bridgePointer);
    // return DivePlugin.mediaGetTime(trackingUUID);
  }

  Future<bool> setTime(int ms) async {
    obslib.mediaSourceSetTime(bridgePointer, ms);
    return true;
    // return DivePlugin.mediaSetTime(trackingUUID, ms);
  }
}
