import 'dart:async';

import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/texture_controller.dart';

class DiveInputTypes {
  DiveInputTypes();
  static Future<List<DiveInputType>> all() => DivePlugin.inputTypes();
}

class DiveInputs {
  static Future<List<DiveVideoInput>> video() => DivePlugin.videoInputs();
}

class DiveSettings {}

class DiveSource {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;
  DiveSource({this.inputType, this.name, this.settings});

  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;
}

class DiveVideoSource extends DiveSource {
  TextureController _controller;
  TextureController get controller => _controller;

  static Future<DiveVideoSource> create(DiveVideoInput videoInput) async {
    if (!await DivePlugin.createSource(videoInput.name, videoInput.id, true)) {
      return null;
    }
    final videoSource = DiveVideoSource();
    videoSource._controller =
        TextureController(name: videoInput.name, sourceId: videoInput.id);

    await videoSource._controller.initialize();
    return videoSource;
  }
}

class DiveAudioSource extends DiveSource {}
