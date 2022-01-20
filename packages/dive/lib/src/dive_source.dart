import 'dart:async';

import 'dive_audio_meter_source.dart';
import 'dive_input.dart';
import 'dive_input_type.dart';
import 'dive_properties.dart';
import 'dive_scene.dart';
import 'dive_stream.dart';
import 'dive_system_log.dart';
import 'dive_tracking.dart';
import 'dive_transform_info.dart';

class DiveVideoMix extends DiveTracking {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    return video;
  }
}

/// A [DiveSource] produces an output stream of frames from a specific input,
/// such as a FaceTime camera, the main system microphone, or a screen capture.
abstract class DiveSource extends DiveNamedTracking {
  final DiveInputType inputType;
  final DiveCoreProperties? properties;
  dynamic pointer;
  List<DiveSourceOutput> outputs = [];
  List<DiveSourceController> controllers = [];

  DiveStream get frameOutput;

  DiveSource({String? name, required this.inputType, this.properties})
      : super(name: name);

  @override
  String toString() {
    return "$runtimeType($hashCode, $name)";
  }

  bool dispose() {
    return true;
  }
}

class DiveAudioSource extends DiveSource {
  DiveAudioSource({String? name, this.input, required DiveInputType inputType})
      : super(name: name, inputType: inputType);

  final DiveInput? input;
  DiveAudioMeterSource? volumeMeter;

  static Future<DiveAudioSource> create(String name, {DiveInput? input}) async {
    final source = DiveAudioSource(
        name: name, input: input, inputType: DiveInputType.audio);

    final properties = DiveCoreProperties();
    final deviceId = source.input == null ? "default" : source.input?.id;
    properties.setString("device_id", deviceId!);

    DiveLog.message("DiveAudioSource.create: ($name) device_id=$deviceId");

    return source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    super.dispose();
    if (volumeMeter != null) {
      volumeMeter?.dispose();
      volumeMeter = null;
    }
    return true;
  }

  @override
  // TODO: implement frameStream
  DiveStream get frameOutput => throw UnimplementedError();
}

/// A video source supports video cameras and other similar devices.
/// This is not a source for playing video files.
class DiveVideoSource extends DiveSource {
  DiveAudioMeterSource? volumeMeter;

  DiveVideoSource({String? name})
      : super(inputType: DiveInputType.video, name: name);

  static Future<DiveVideoSource> create(DiveInput videoInput) async {
    final source = DiveVideoSource(name: videoInput.name);
    return source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    if (volumeMeter != null) {
      volumeMeter?.dispose();
      volumeMeter = null;
    }
    super.dispose();
    return true;
  }

  @override
  // TODO: implement frameStream
  DiveStream get frameOutput => throw UnimplementedError();
}

/// Used for changing the order of items (for example, filters in a source,
/// or items in a scene)
enum DiveSceneItemMovement {
  MOVE_UP,
  MOVE_DOWN,
  MOVE_TOP,
  MOVE_BOTTOM,
}

class DivePointerSceneItem {
  DivePointerSceneItem(dynamic pointer);
}

class DivePluginExt {
  static Future<DiveTransformInfo> getSceneItemInfo(
      DivePointerSceneItem item) async {
    return DiveTransformInfo(); //.fromMap(info);
  }

  static bool setSceneItemInfo(
      DivePointerSceneItem item, DiveTransformInfo info) {
    return false;
  }

  static List<DiveInputType> inputTypes() {
    return []; // devices.map(DiveInputType.fromJson).toList();
  }

  static List<DiveInput> inputsFromType(String typeId) {
    return []; // devices.map(DiveInput.fromMap).toList();
  }

  static List<DiveInput> audioInputs() {
    return []; // devices.map(DiveInput.fromMap).toList();
  }

  static List<DiveInput> videoInputs() {
    return []; // devices.map(DiveInput.fromMap).toList();
  }
}

class DiveSceneItem {
  final DivePointerSceneItem item;
  final DiveSource source;
  final DiveScene scene;

  DiveSceneItem(
      {required this.item, required this.source, required this.scene});

  Future<DiveTransformInfo> getTransformInfo() async =>
      await DivePluginExt.getSceneItemInfo(item);

  Future<bool> updateTransformInfo(DiveTransformInfo info) async {
    // get transform info
    final currentInfo = await getTransformInfo();

    // update info with changes
    final newInfo = currentInfo.copyFrom(info);

    // set transform info
    return DivePluginExt.setSceneItemInfo(item, newInfo);
  }

  /// Set the Z order of a scene item within the scene.
  void setOrder(DiveSceneItemMovement movement) {}

  /// Remove the item from the scene.
  void remove() {}

  /// Make the item visible.
  set visible(bool visible) {}

  bool get visible {
    return false;
  }

  @override
  String toString() {
    return "source=${source.name} | scene=$scene";
  }
}

class DiveSourceFrameConfiguration extends DiveSourceOutputConfiguration {
  final int width;
  final int height;
  DiveSourceFrameConfiguration(this.width, this.height);
}

/// A source controller that handles actions sent to a source.
class DiveSourceController {
  // actions
}

/// A microphone controller.
class DiveMicrophoneController extends DiveSourceController {}

/// A source output which includes a stream.
class DiveSourceOutput {
  final Stream dataStream;
  final DiveSourceOutputType type;

  DiveSourceOutput(this.dataStream, this.type);
}

class DiveAudioSourceOutput extends DiveSourceOutput {
  DiveAudioSourceOutput(Stream dataStream, DiveSourceOutputType type)
      : super(dataStream, type);
}

class DiveFrameSourceOutput extends DiveSourceOutput {
  DiveSourceFrameConfiguration? configuration;

  DiveFrameSourceOutput(Stream dataStream, DiveSourceOutputType type)
      : super(dataStream, type);
}

class DiveDrawingSourceOutput extends DiveSourceOutput {
  DiveDrawingSourceOutput(Stream dataStream, DiveSourceOutputType type)
      : super(dataStream, type);
}

class DiveTextSourceOutput extends DiveSourceOutput {
  DiveTextSourceOutput(Stream dataStream, DiveSourceOutputType type)
      : super(dataStream, type);
}

// class DiveSourceInternal extends DiveTracking {
//   List<DiveSourceOutput> outputs;
//   List<DiveSourceController> controllers;
// }
