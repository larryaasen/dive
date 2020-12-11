import 'dart:async';

import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/texture_controller.dart';
import 'package:uuid/uuid.dart';

/// Simple, fast generation of RFC4122 UUIDs
final _uuid = Uuid();

class DiveInputTypes {
  DiveInputTypes();
  static Future<List<DiveInputType>> all() => DivePlugin.inputTypes();
}

class DiveInputs {
  static Future<List<DiveVideoInput>> video() => DivePlugin.videoInputs();
}

// TODO: DiveSettings needs to be implemented
class DiveSettings {}

/// Use this class as a base class or a mixin
class DiveController {
  TextureController _controller;
  TextureController get controller => _controller;

  /// This must be called right after this class is instantiated and
  /// before doing anything else.
  Future<void> setupController(String trackingUUID) async {
    _controller = TextureController(trackingUUID: trackingUUID);
    await _controller.initialize();
    return;
  }

  /// Release the texture controller.
  void releaseController() {
    _controller.dispose();
  }
}

class DiveBase {
  /// A RFC4122 V1 UUID (time-based)
  final String _trackingUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get trackingUUID => _trackingUUID;

  DiveBase() : _trackingUUID = _uuid.v1();
}

class DiveVideoMix extends DiveBase with DiveController {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    await video.setupController(video.trackingUUID);
    if (!await DivePlugin.createVideoMix(video.trackingUUID)) {
      return null;
    }
    return video;
  }
}

class DiveSource extends DiveBase {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;

  DiveSource({this.inputType, this.name, this.settings});

  // TODO: DiveSource.create() needs to be implemented
  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;
}

class DiveTextureSource extends DiveSource with DiveController {
  DiveTextureSource({DiveInputType inputType, String name})
      : super(inputType: inputType, name: name);
}

class DiveVideoSource extends DiveSource with DiveController {
  DiveVideoSource({String name})
      : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveVideoInput videoInput) async {
    final source = DiveVideoSource(name: 'my video');
    await source.setupController(source.trackingUUID);
    if (!await DivePlugin.createVideoSource(
        source.trackingUUID, videoInput.name, videoInput.id)) {
      return null;
    }
    return source;
  }
}

class DiveMediaSource extends DiveTextureSource {
  DiveMediaSource({String name})
      : super(inputType: DiveInputType.mediaSource, name: name);

  static Future<DiveMediaSource> create(String localFile) async {
    final source = DiveMediaSource(name: 'my media');
    await source.setupController(source.trackingUUID);
    if (!await DivePlugin.createMediaSource(source.trackingUUID, localFile)) {
      return null;
    }
    return source;
  }

  Future<bool> play() async {
    return await DivePlugin.mediaPlayPause(trackingUUID, false);
  }

  Future<bool> pause() async {
    return await DivePlugin.mediaPlayPause(trackingUUID, true);
  }

  Future<bool> stop() async {
    return await DivePlugin.mediaStop(trackingUUID);
  }
}

// TODO: DiveAudioSource needs to be implemented
class DiveAudioSource extends DiveSource {}
