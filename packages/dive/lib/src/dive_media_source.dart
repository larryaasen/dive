import 'dart:async';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_audio_meter_source.dart';
import 'dive_core.dart';
import 'dive_input_type.dart';
import 'dive_settings.dart';
import 'dive_settings_data.dart';
import 'dive_sources.dart';

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
class DiveMediaSourceState extends Equatable {
  /// The current playback time.
  final int currentTime;

  /// The full duration of the media playback time, in milliseconds.
  final int duration;

  /// The current media playback state.
  final DiveMediaState mediaState;

  const DiveMediaSourceState(
      {this.currentTime = 0, this.duration = 0, this.mediaState = DiveMediaState.NONE});

  /// Indicates to output this instance's [props] in [toString].
  @override
  bool get stringify => true;

  /// Returns the list of properties used to facilitate [operator ==].
  @override
  List<Object> get props => [currentTime, duration, mediaState];
}

class _DiveMediaSourceStateNotifier extends StateNotifier<DiveMediaSourceState> {
  DiveMediaSourceState get stateModel => state;

  _DiveMediaSourceStateNotifier(DiveMediaSourceState stateModel)
      : super(stateModel ?? DiveMediaSourceState());

  void updateMediaState(DiveMediaSourceState stateModel) => state = stateModel;
}

class DiveMediaSourceSettings extends DiveSettings {
  String get localFile => get('local_file');
  bool get isLocalFile => get('is_local_file');
  bool get looping => get('looping');

  bool get clearOnMediaEnd => get('clear_on_media_end');
  bool get restartOnActivate => get('restart_on_activate');
  bool get linearAlpha => get('linear_alpha');

  int get reconnectDelaySec => get('reconnect_delay_sec');
  int get bufferingMb => get('buffering_mb');
  int get speedPercent => get('speed_percent');

  DiveMediaSourceSettings({
    String localFile,
    bool isLocalFile = true,
    bool looping = false,
    bool clearOnMediaEnd = true,
    bool restartOnActivate = true,
    bool linearAlpha = false,
    int reconnectDelaySec = 10,
    int bufferingMb = 2,
    int speedPercent = 100,
  }) {
    set('local_file', localFile);
    set('is_local_file', isLocalFile);
    set('looping', looping);
    set('clear_on_media_end', clearOnMediaEnd);
    set('restart_on_activate', restartOnActivate);
    set('linear_alpha', linearAlpha);
    set('reconnect_delay_sec', reconnectDelaySec);
    set('buffering_mb', bufferingMb);
    set('speed_percent', speedPercent);
  }
}

/// Represents a ffmpeg_source media source.
class DiveMediaSource extends DiveTextureSource {
  final stateProvider =
      StateNotifierProvider<_DiveMediaSourceStateNotifier>((ref) => _DiveMediaSourceStateNotifier(null));

  // final String localFile;
  final DiveMediaSourceSettings settings;

  DiveAudioMeterSource volumeMeter;

  /// The state syncing interval (msec).
  final stateSyncInterval;

  Timer _syncStateTimer;

  DiveMediaSource(String name, {this.settings, this.stateSyncInterval = 500})
      : super(inputType: DiveInputType.mediaSource, name: name) {
    if (stateSyncInterval > 0) {
      _syncStateTimer = Timer.periodic(Duration(milliseconds: stateSyncInterval), _timerCallback);
    }
  }
  static Future<DiveMediaSource> create({
    String name = 'my media',
    DiveMediaSourceSettings settings,
    bool requiresVideoMonitor = true,
  }) async {
    final source = DiveMediaSource(name, settings: settings);
    if (requiresVideoMonitor) await source.setupTexture(source.trackingUUID);

    final data = settings.toData();
    source.pointer = obslib.createMediaSource(
      sourceUuid: source.trackingUUID,
      name: name,
      settings: data,
    );

    data.dispose();
    await source.syncState();

    // TODO: try adding frame callback
    // await obslib.addSourceFrameCallback(source.trackingUUID, source.pointer.address);

    // Turn on the default audio monitoring device so we can hear the audio.
    // TODO: is this really needed here?
    if (source.pointer != null) {
      obslib.sourceSetMonitoringType(source.pointer);
    }

    return source.pointer == null ? null : source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    if (_syncStateTimer != null) {
      _syncStateTimer.cancel();
      _syncStateTimer = null;
    }

    // obslib.removeSourceFrameCallback(trackingUUID, pointer.address);
    obslib.releaseSource(pointer);
    releaseController();

    if (volumeMeter != null) {
      volumeMeter.dispose();
      volumeMeter = null;
    }

    super.dispose();
    return true;
  }

  void _timerCallback(Timer timer) {
    _syncState();
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
    final currentStateModel = DiveCore.notifierFor(stateProvider).stateModel;
    final newStateModel = await getState();
    if (currentStateModel != newStateModel) {
      DiveCore.notifierFor(stateProvider).updateMediaState(newStateModel);
    }
    return;
  }

  /// Get the media source state for this media source.
  Future<DiveMediaSourceState> getState() async {
    final mediaState = obslib.mediaSourceGetState(pointer);
    final duration = obslib.mediaSourceGetDuration(pointer);
    final ms = obslib.mediaSourceGetTime(pointer);
    return DiveMediaSourceState(
        currentTime: ms, duration: duration, mediaState: DiveMediaState.values[mediaState]);
  }

  Future<bool> play() async {
    obslib.mediaSourcePlayPause(pointer, false);
    await syncState();

    return true;
  }

  Future<bool> pause() async {
    obslib.mediaSourcePlayPause(pointer, true);
    await syncState();
    return true;
  }

  Future<bool> restart() async {
    obslib.mediaSourceRestart(pointer);
    await syncState();
    return true;
  }

  Future<bool> stop() async {
    obslib.mediaSourceStop(pointer);
    await syncState();
    return true;
  }

  Future<int> getDuration() async {
    return obslib.mediaSourceGetDuration(pointer);
  }

  Future<int> getTime() async {
    return obslib.mediaSourceGetTime(pointer);
  }

  Future<bool> setTime(int ms) async {
    obslib.mediaSourceSetTime(pointer, ms);
    return true;
  }
}
