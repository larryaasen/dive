import 'dart:async';
import 'dive_audio_meter_source.dart';
import 'dive_core.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_input_type.dart';
import 'dive_properties.dart';
import 'dive_source.dart';
import 'dive_stream.dart';

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

class _DiveMediaSourceStateNotifier
    extends StateNotifier<DiveMediaSourceState> {
  DiveMediaSourceState get stateModel => state;

  _DiveMediaSourceStateNotifier(DiveMediaSourceState? stateModel)
      : super(stateModel ?? DiveMediaSourceState());

  void updateMediaState(DiveMediaSourceState stateModel) {
    state = stateModel;
  }
}

/// A media source supports video files played locally or remotely.
/// This is not a source for video cameras.
class DiveMediaSource extends DiveSource {
  final stateProvider = StateNotifierProvider<_DiveMediaSourceStateNotifier>(
      (ref) => _DiveMediaSourceStateNotifier(null));

  Timer? _playbackTimer;

  String? _localFile;
  String? get localFile => _localFile;

  DiveAudioMeterSource? volumeMeter;

  @override
  // TODO: implement frameOutput
  DiveStream get frameOutput => throw UnimplementedError();

  /// Create an media source.
  factory DiveMediaSource.create(
      {String? name, DiveCoreProperties? properties}) {
    final source = DiveMediaSource._(name: name, properties: properties);
    return source;
  }

  DiveMediaSource._({String? name, DiveCoreProperties? properties})
      : super(
            inputType: DiveInputType.media,
            name: name,
            properties: properties) {
    _playbackTimer =
        Timer.periodic(Duration(milliseconds: 1000), timerCallback);

    if (properties != null) {}
  }

  // static Future<DiveMediaSource> create(String localFile) async {
  //   final source = DiveMediaSource(name: 'my media', localFile: localFile);
  //   // await source.setupController(source.trackingUUID);
  //   // source.pointer = oldlib.createMediaSource(source.trackingUUID, localFile);
  //   await source.syncState();
  //   // return source.pointer == null ? null : source;
  //   return source;
  // }

  /// Remove this media source.
  bool remove() {
    // TODO: finish the remove() function.
    _playbackTimer?.cancel();
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
    // final mediaState = oldlib.mediaSourceGetState(pointer);
    // final duration = oldlib.mediaSourceGetDuration(pointer);
    // final ms = oldlib.mediaSourceGetTime(pointer);
    return DiveMediaSourceState();
    // currentTime: ms,
    // duration: duration,
    // mediaState: DiveMediaState.values[mediaState]);
  }

  Future<bool> play() async {
    // oldlib.mediaSourcePlayPause(pointer, false);
    await syncState();
    return true;
  }

  Future<bool> pause() async {
    // oldlib.mediaSourcePlayPause(pointer, true);
    await syncState();
    return true;
  }

  Future<bool> restart() async {
    // oldlib.mediaSourceRestart(pointer);
    await syncState();
    return true;
  }

  Future<bool> stop() async {
    // oldlib.mediaSourceStop(pointer);
    await syncState();
    return true;
  }

  Future<int> getDuration() async {
    return 0; // oldlib.mediaSourceGetDuration(pointer);
  }

  Future<int> getTime() async {
    return 0; // oldlib.mediaSourceGetTime(pointer);
  }

  Future<bool> setTime(int ms) async {
    // oldlib.mediaSourceSetTime(pointer, ms);
    return true;
  }
}
