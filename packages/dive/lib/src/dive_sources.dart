import 'dart:async';

import 'package:dive/dive.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/foundation.dart';

import 'dive_plugin.dart';

// TODO: DiveSettings needs to be implemented
class DiveSettings {}

/// A texture controller for displaying video and image frames.
/// Use this class as a base class or a mixin.
class DiveTextureSetup {
  DiveTextureController _controller;
  DiveTextureController get controller => _controller;

  /// This must be called right after this class is instantiated and
  /// before doing anything else.
  Future<void> setupTexture(String trackingUUID) async {
    _controller = DiveTextureController(trackingUUID: trackingUUID);
    await _controller.initialize();
    return;
  }

  /// Release the texture controller.
  void releaseController() {
    _controller.dispose();
    _controller = null;
  }
}

/// Provides a unique tracking ID.
class DiveTracking {
  /// A RFC4122 V1 UUID (time-based)
  final String _trackingUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get trackingUUID => _trackingUUID;

  DiveTracking() : _trackingUUID = DiveUuid.newId();
}

/// A video mix contains the raw video frames of the final video mix.
/// It uses a texture controller for displaying the frames.
class DiveVideoMix extends DiveTracking with DiveTextureSetup {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    await video.setupTexture(video.trackingUUID);
    if (!await obslib.createVideoMix(video.trackingUUID)) {
      return null;
    }
    return video;
  }
}

class DiveSource extends DiveTracking {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;
  DivePointer pointer;

  DiveSource({this.inputType, this.name, this.settings});

  // TODO: DiveSource.create() needs to be implemented
  static Future<DiveSource> create({DiveInputType inputType, String name, DiveSettings settings}) => null;

  @override
  String toString() {
    return "${this.runtimeType}(${this.hashCode}, $name)";
  }

  @mustCallSuper
  bool dispose() {
    pointer = null;
    return true;
  }
}

/// Combines a [DiveSource] with a [DiveTextureSetup] so that a source can
/// display an image or video frame in a Flutter texture.
abstract class DiveTextureSource extends DiveSource with DiveTextureSetup {
  DiveTextureSource({DiveInputType inputType, String name}) : super(inputType: inputType, name: name);

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
    final source = DiveAudioSource(name: name, input: input, inputType: DiveInputType.audioSource);

    final data = obslib.createData();
    final deviceId = source.input == null ? "default" : source.input.id;
    data.setString("device_id", deviceId);

    print("DiveAudioSource.create: device_id=$deviceId");
    source.pointer = obslib.createSource(
      sourceUuid: source.trackingUUID,
      inputTypeId: source.inputType.id,
      name: source.name,
      settings: data,
    );

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

// class DiveTextureSource extends DiveSource with DiveTextureSetup {

/// A video source, such as a camera.
class DiveVideoSource extends DiveSource with DiveTextureSetup {
  DiveAudioMeterSource volumeMeter;

  DiveVideoSource({String name}) : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveInput videoInput) async {
    final source = DiveVideoSource(name: videoInput.name);
    source.pointer = obslib.createVideoSource(source.trackingUUID, videoInput.name, videoInput.id);
    await source.setupTexture(source.trackingUUID);
    await obslib.addSourceFrameCallback(source.trackingUUID, source.pointer.address);
    return source.pointer == null ? null : source;
  }

  /// Release the resources associated with this source.
  @override
  bool dispose() {
    obslib.removeSourceFrameCallback(trackingUUID, pointer.address);
    obslib.releaseSource(pointer);
    releaseController();
    if (volumeMeter != null) {
      volumeMeter.dispose();
      volumeMeter = null;
    }
    super.dispose();
    return true;
  }
}

/// The source for an image that is a texture source.
class DiveImageSource extends DiveTextureSource {
  DiveImageSource({String name}) : super(inputType: DiveInputType.imageSource, name: name);

  static Future<DiveImageSource> create(String file) async {
    final source = DiveImageSource(name: 'my image');
    await source.setupTexture(source.trackingUUID);
    source.pointer = obslib.createImageSource(source.trackingUUID, file);
    // if (!await DivePlugin.createImageSource(source.trackingUUID, file)) {
    //   return null;
    // }
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

class DiveSceneItem {
  final DivePointerSceneItem item;
  final DiveSource source;
  final DiveScene scene;

  DiveSceneItem({this.item, this.source, this.scene});

  Future<DiveTransformInfo> getTransformInfo() async => await DivePluginExt.getSceneItemInfo(item);

  Future<void> updateTransformInfo(DiveTransformInfo info) async {
    // get transform info
    final currentInfo = await getTransformInfo();

    // update info with changes
    final newInfo = currentInfo.copyFrom(info);

    // set transform info
    return await DivePluginExt.setSceneItemInfo(item, newInfo);
  }

  /// Set the Z order of a scene item within the scene.
  void setOrder(DiveSceneItemMovement movement) {
    obslib.sceneItemSetOrder(item, movement.index);
  }

  /// Remove the item from the scene.
  void remove() {
    DiveSystemLog.message('DiveSceneItem.remove item=$this', group: 'dive');
    obslib.sceneItemRemove(item);
  }

  /// Make the item visible.
  set visible(bool visible) {
    obslib.sceneItemSetVisible(item, visible);
  }

  bool get visible {
    return obslib.sceneItemIsVisible(item);
  }

  @override
  String toString() {
    return "DiveSceneItem item=${item.pointer}, source=${source.name}";
  }
}
