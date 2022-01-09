import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dive_core.dart';

class DiveCoreSettings {
  DiveCoreSettings() {}

  void dispose() {}

  void setBool(String name, bool value) {}

  void setString(String name, String value) {}
}

void exampleUseData() {
  final data = DiveCoreSettings();
  data.setBool("is_local_file", true);
  data.dispose();
}

// TODO: DiveSettings needs to be implemented
class DiveSettings {}

/// This is a texture controller for displaying video and image frames.
/// Use this class as a base class or a mixin.
class DiveTextureController {
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
    _controller = null;
  }
}

class DiveTracking {
  /// A RFC4122 V1 UUID (time-based)
  final String _trackingUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get trackingUUID => _trackingUUID;

  DiveTracking() : _trackingUUID = DiveUuid.newId();
}

class DiveVideoMix extends DiveTracking with DiveTextureController {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    await video.setupController(video.trackingUUID);
    return video;
  }
}

enum DiveSourceOutputType {
  AUDIO,
  DRAWING,
  FRAME,
  TEXT,
}

class DiveSourceOutputConfiguration {}

class DiveSourceFrameConfiguration extends DiveSourceOutputConfiguration {
  int width;
  int height;
}

/// This object is sent to every downstream process of the source. It is sent
/// as one item in the stream.
class DiveDataStreamItem {
  dynamic data;
  DiveSourceOutputType type;
  DiveSourceOutputConfiguration configuration;
}

class DiveSourceController {
  // actions
}

class DiveMicrophoneController extends DiveSourceController {}

class DiveSourceOutput {
  Stream dataStream;
  DiveSourceOutputType type;
}

class DiveAudioSourceOutput extends DiveSourceOutput {}

class DiveFrameSourceOutput extends DiveSourceOutput {
  DiveSourceFrameConfiguration configuration;
}

class DiveDrawingSourceOutput extends DiveSourceOutput {}

class DiveTextSourceOutput extends DiveSourceOutput {}

class DiveSourceInternal extends DiveTracking {
  List<DiveSourceOutput> outputs;
  List<DiveSourceController> controllers;
}

class DiveSource extends DiveTracking {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;
  dynamic pointer;
  DiveSourceInternal _internalSource;

  DiveSource({this.inputType, this.name, this.settings});

  // TODO: DiveSource.create() needs to be implemented
  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;

  @override
  String toString() {
    return "${this.runtimeType}(${this.hashCode}, $name)";
  }

  @mustCallSuper
  bool dispose() {
    return true;
  }
}

class DiveTextureSource extends DiveSource with DiveTextureController {
  DiveTextureSource({DiveInputType inputType, String name})
      : super(inputType: inputType, name: name);

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    super.dispose();
    return true;
  }
}

class DiveAudioSource extends DiveSource {
  DiveAudioSource({String name, this.input, DiveInputType inputType})
      : super(name: name, inputType: inputType);

  final DiveInput input;
  DiveAudioMeterSource volumeMeter;

  static Future<DiveAudioSource> create(String name, {DiveInput input}) async {
    final source = DiveAudioSource(
        name: name, input: input, inputType: DiveInputType.audioSource);

    final data = DiveCoreSettings();
    final deviceId = source.input == null ? "default" : source.input.id;
    data.setString("device_id", deviceId);

    print("DiveAudioSource.create: device_id=$deviceId");

    data.dispose();
    return source.pointer == null ? null : source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    super.dispose();
    if (volumeMeter != null) {
      volumeMeter.dispose();
      volumeMeter = null;
    }
    return true;
  }
}

class DiveVideoSource extends DiveSource with DiveTextureController {
  DiveAudioMeterSource volumeMeter;

  DiveVideoSource({String name})
      : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveInput videoInput) async {
    final source = DiveVideoSource(name: videoInput.name);
    await source.setupController(source.trackingUUID);
    return source.pointer == null ? null : source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    releaseController();
    if (volumeMeter != null) {
      volumeMeter.dispose();
      volumeMeter = null;
    }
    super.dispose();
    return true;
  }
}

class DiveImageSource extends DiveTextureSource {
  DiveImageSource({String name})
      : super(inputType: DiveInputType.imageSource, name: name);

  static Future<DiveImageSource> create(String file) async {
    final source = DiveImageSource(name: 'my image');
    await source.setupController(source.trackingUUID);
    return source.pointer == null ? null : source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    super.dispose();
    return true;
  }
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

  DiveSceneItem({this.item, this.source, this.scene});

  Future<DiveTransformInfo> getTransformInfo() async =>
      await DivePluginExt.getSceneItemInfo(item);

  Future<void> updateTransformInfo(DiveTransformInfo info) async {
    // get transform info
    final currentInfo = await getTransformInfo();

    // update info with changes
    final newInfo = currentInfo.copyFrom(info);

    // set transform info
    return await DivePluginExt.setSceneItemInfo(item, newInfo);
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
