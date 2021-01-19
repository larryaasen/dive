import 'dart:async';

import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/texture_controller.dart';
import 'package:uuid/uuid.dart';

/// Simple, fast generation of RFC4122 UUIDs
final _uuid = Uuid();

/// Count of scenes created
int _sceneCount = 0;

class DiveInputTypes {
  DiveInputTypes();
  static Future<List<DiveInputType>> all() => DivePluginExt.inputTypes();
}

class DiveInputs {
  static Future<List<DiveInput>> fromType(String typeId) =>
      DivePluginExt.inputsFromType(typeId);
  static Future<List<DiveInput>> audio() => DivePluginExt.audioInputs();
  static Future<List<DiveInput>> video() async => DiveCore.bridge
      .videoInputs()
      .map(DiveInput.fromMap)
      .toList(); // DivePluginExt.videoInputs();

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
  }
}

class DiveTracking {
  /// A RFC4122 V1 UUID (time-based)
  final String _trackingUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get trackingUUID => _trackingUUID;

  DiveTracking() : _trackingUUID = _uuid.v1();
}

class DiveVideoMix extends DiveTracking with DiveTextureController {
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

class DiveSource extends DiveTracking {
  final DiveInputType inputType;
  final String name;
  final DiveSettings settings;
  DiveBridgePointer bridgePointer;

  DiveSource({this.inputType, this.name, this.settings});

  // TODO: DiveSource.create() needs to be implemented
  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;
}

class DiveTextureSource extends DiveSource with DiveTextureController {
  DiveTextureSource({DiveInputType inputType, String name})
      : super(inputType: inputType, name: name);
}

class DiveAudioSource extends DiveSource {
  DiveAudioSource({String name})
      : super(inputType: DiveInputType.audioSource, name: name);

  static Future<DiveAudioSource> create(String name) async {
    final source = DiveAudioSource(name: name);
    if (!await DivePlugin.createSource(
        // TODO: need to add 'device_id' for audio, such as 'default'
        source.trackingUUID,
        source.inputType.id,
        name,
        false)) {
      return null;
    }
    return source;
  }
}

class DiveVideoSource extends DiveSource with DiveTextureController {
  DiveVideoSource({String name})
      : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveInput videoInput) async {
    final source = DiveVideoSource(name: 'my video');
    await source.setupController(source.trackingUUID);
    source.bridgePointer = DiveCore.bridge
        .createVideoSource(source.trackingUUID, videoInput.name, videoInput.id);
    DivePlugin.addSourceFrameCallback(
        source.trackingUUID, source.bridgePointer.address);
    // if (!await DivePlugin.createVideoSource(
    //     source.trackingUUID, videoInput.name, videoInput.id)) {
    //   return null;
    // }
    return source;
  }
}

class DiveImageSource extends DiveTextureSource {
  DiveImageSource({String name})
      : super(inputType: DiveInputType.imageSource, name: name);

  static Future<DiveImageSource> create(String file) async {
    final source = DiveImageSource(name: 'my image');
    await source.setupController(source.trackingUUID);
    if (!await DivePlugin.createImageSource(source.trackingUUID, file)) {
      return null;
    }
    return source;
  }
}

class DiveAlign {
  static const CENTER = 0;
  static const LEFT = (1 << 0);
  static const RIGHT = (1 << 1);
  static const TOP = (1 << 2);
  static const BOTTOM = (1 << 3);

  final int alignment;
  DiveAlign({this.alignment = CENTER});
}

class DiveVec2 {
  final double x, y;

  DiveVec2(this.x, this.y);

  static DiveVec2 fromMap(Map map) {
    return DiveVec2(map['x'], map['y']);
  }
}

enum DiveBoundsType {
  /// no bounds
  NONE,

  /// stretch (ignores base scale) */
  STRETCH,

  /// scales to inner rectangle */
  SCALE_INNER,

  /// scales to outer rectangle */
  SCALE_OUTER,

  /// scales to the width  */
  SCALE_TO_WIDTH,

  /// scales to the height */
  SCALE_TO_HEIGHT,

  /// no scaling, maximum size only */
  MAX_ONLY,
}

class DiveTransformInfo {
  final DiveVec2 pos;
  final double rot;
  final DiveVec2 scale;
  final DiveAlign alignment;
  final DiveBoundsType boundsType;
  final DiveAlign boundsAlignment;
  final DiveVec2 bounds;

  DiveTransformInfo(
      {this.pos,
      this.rot,
      this.scale,
      this.alignment,
      this.boundsType,
      this.boundsAlignment,
      this.bounds});

  DiveTransformInfo copyWith({
    pos,
    rot,
    scale,
    alignment,
    boundsType,
    boundsAlignment,
    bounds,
  }) {
    return DiveTransformInfo(
      pos: pos ?? this.pos,
      rot: rot ?? this.rot,
      scale: scale ?? this.scale,
      alignment: alignment ?? this.alignment,
      boundsType: boundsType ?? this.boundsType,
      boundsAlignment: boundsAlignment ?? this.boundsAlignment,
      bounds: bounds ?? this.bounds,
    );
  }

  DiveTransformInfo copyFrom(DiveTransformInfo info) {
    return this.copyWith(
      pos: info.pos,
      rot: info.rot,
      scale: info.scale,
      alignment: info.alignment,
      boundsType: info.boundsType,
      boundsAlignment: info.boundsAlignment,
      bounds: info.bounds,
    );
  }

  static DiveTransformInfo fromMap(Map map) {
    return DiveTransformInfo(
      pos: DiveVec2.fromMap(map['pos']),
      rot: map['rot'],
      scale: DiveVec2.fromMap(map['scale']),
      alignment: DiveAlign(alignment: map['alignment']),
      boundsType: DiveBoundsType.values[map['bounds_type']],
      boundsAlignment: DiveAlign(alignment: map['bounds_alignment']),
      bounds: DiveVec2.fromMap(map['bounds']),
    );
  }

  Map toMap() {
    return {
      'pos': {'x': pos.x, 'y': pos.y},
      'rot': rot,
      'scale': {'x': scale.x, 'y': scale.y},
      'alignment': alignment.alignment,
      'bounds_type': boundsType.index,
      'bounds_alignment': boundsAlignment.alignment,
      'bounds': {'x': bounds.x, 'y': bounds.y},
    };
  }
}

class DiveSceneItem {
  final int itemId;
  final DiveSource source;
  final DiveScene scene;

  DiveSceneItem({this.itemId, this.source, this.scene});

  Future<void> updateTransformInfo(DiveTransformInfo info) async {
    // get transform info
    final currentInfo =
        await DivePluginExt.getSceneItemInfo(scene.trackingUUID, itemId);

    // update info with changes
    final newInfo = currentInfo.copyFrom(info);

    // set transform info
    return await DivePluginExt.setSceneItemInfo(
        scene.trackingUUID, itemId, newInfo);
  }
}

class DiveScene extends DiveTracking {
  static const MAX_CHANNELS = 64;

  final List<DiveSceneItem> _sceneItems = [];
  DiveBridgePointer bridgePointer;

  static Future<DiveScene> create(String name) async {
    if (_sceneCount > 0) {
      throw UnsupportedError('multiple scenes are not supported.');
    }
    _sceneCount++;

    final scene = DiveScene();
    scene.bridgePointer = DiveCore.bridge.createScene(scene.trackingUUID, name);

    // if (!await DivePlugin.createScene(scene.trackingUUID, name)) {
    //   return null;
    // }

    return scene;
  }

  Future<DiveSceneItem> addSource(DiveSource source) async {
    final itemId =
        DiveCore.bridge.addSource(bridgePointer, source.bridgePointer);
    // await DivePlugin.addSource(trackingUUID, source.trackingUUID);
    if (itemId == 0) {
      return null;
    }
    final sceneItem =
        DiveSceneItem(itemId: itemId, source: source, scene: this);
    _sceneItems.add(sceneItem);
    return sceneItem;
  }
}

// class DiveStateNotifier<T> extends StateNotifier<T> {
//   DiveStateNotifier(T initialState) : super(initialState);

//   void change(T newState) {
//     state = newState;
//   }
// }
