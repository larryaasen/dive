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

class DiveSource {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;

  DiveSource({this.inputType, this.name, this.settings})
      : _sourceUUID = _uuid.v1();

  /// A RFC4122 V1 UUID (time-based)
  final String _sourceUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get sourceUUID => _sourceUUID;

  // TODO: DiveSource.create() needs to be implemented
  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;
}

class DiveTextureSource extends DiveSource {
  DiveTextureSource({DiveInputType inputType, String name})
      : super(inputType: inputType, name: name);

  TextureController _controller;
  TextureController get controller => _controller;

  /// This must be called right after this class is instantiated and
  /// before creating the source.
  Future<void> setupController() async {
    _controller = TextureController(sourceUUID: _sourceUUID);
    await _controller.initialize();
    return;
  }
}

class DiveVideoSource extends DiveTextureSource {
  DiveVideoSource({String name})
      : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveVideoInput videoInput) async {
    final source = DiveVideoSource(name: 'my video');
    await source.setupController();
    if (!await DivePlugin.createVideoSource(
        source.sourceUUID, videoInput.name, videoInput.id)) {
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
    await source.setupController();
    if (!await DivePlugin.createMediaSource(source.sourceUUID, localFile)) {
      return null;
    }
    return source;
  }

  Future<bool> play() async {
    return await DivePlugin.mediaPlayPause(sourceUUID, false);
  }

  Future<bool> pause() async {
    return await DivePlugin.mediaPlayPause(sourceUUID, true);
  }

  Future<bool> stop() async {
    return await DivePlugin.mediaStop(sourceUUID);
  }
}

// TODO: DiveAudioSource needs to be implemented
class DiveAudioSource extends DiveSource {}
