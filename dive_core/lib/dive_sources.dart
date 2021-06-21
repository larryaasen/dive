import 'dart:async';

import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/texture_controller.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:uuid/uuid.dart';

/// Simple, fast generation of RFC4122 UUIDs
final _uuid = Uuid();

abstract class DiveUuid {
  static String newId() => _uuid.v1();
}

/// Count of scenes created
int _sceneCount = 0;

class DiveInputTypes {
  DiveInputTypes();
  static Future<List<DiveInputType>> all() async =>
      obslib.inputTypes().map(DiveInputType.fromJson).toList();
  // DivePluginExt.inputTypes();
}

class DiveInputs {
  static List<DiveInput> fromType(String typeId) =>
      DivePluginExt.inputsFromType(typeId);
  static List<DiveInput> audio() =>
      obslib.audioInputs().map(DiveInput.fromMap).toList();
  // DivePluginExt.audioInputs();
  static List<DiveInput> video() =>
      obslib.videoInputs().map(DiveInput.fromMap).toList();
  // DivePluginExt.videoInputs();
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

  DiveTracking() : _trackingUUID = DiveUuid.newId();
}

class DiveVideoMix extends DiveTracking with DiveTextureController {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    await video.setupController(video.trackingUUID);
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
  static Future<DiveSource> create(
          {DiveInputType inputType, String name, DiveSettings settings}) =>
      null;

  @override
  String toString() {
    return "${this.runtimeType}(${this.hashCode}, $name)";
  }
}

class DiveTextureSource extends DiveSource with DiveTextureController {
  DiveTextureSource({DiveInputType inputType, String name})
      : super(inputType: inputType, name: name);
}

class DiveAudioSource extends DiveSource {
  DiveAudioSource({String name, this.input, DiveInputType inputType})
      : super(name: name, inputType: inputType);

  final DiveInput input;
  DiveAudioMeterSource volumeMeter;

  static Future<DiveAudioSource> create(String name, {DiveInput input}) async {
    final source = DiveAudioSource(
        name: name, input: input, inputType: DiveInputType.audioSource);

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
}

class DiveVideoSource extends DiveSource with DiveTextureController {
  DiveAudioMeterSource volumeMeter;

  DiveVideoSource({String name})
      : super(inputType: DiveInputType.videoCaptureDevice, name: name);

  static Future<DiveVideoSource> create(DiveInput videoInput) async {
    final source = DiveVideoSource(name: videoInput.name);
    await source.setupController(source.trackingUUID);
    source.pointer = obslib.createVideoSource(
        source.trackingUUID, videoInput.name, videoInput.id);
    obslib.addSourceFrameCallback(source.trackingUUID, source.pointer.address);
    return source.pointer == null ? null : source;
  }
}

class DiveImageSource extends DiveTextureSource {
  DiveImageSource({String name})
      : super(inputType: DiveInputType.imageSource, name: name);

  static Future<DiveImageSource> create(String file) async {
    final source = DiveImageSource(name: 'my image');
    await source.setupController(source.trackingUUID);
    source.pointer = obslib.createImageSource(source.trackingUUID, file);
    // if (!await DivePlugin.createImageSource(source.trackingUUID, file)) {
    //   return null;
    // }
    return source.pointer == null ? null : source;
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
  void setOrder(DiveSceneItemMovement movement) {
    obslib.sceneItemSetOrder(item, movement.index);
  }

  /// Remove the item from the scene.
  void remove() {
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
    return "source=${source.name} | scene=$scene";
  }
}

class DiveScene extends DiveTracking {
  static const MAX_CHANNELS = 64;

  // TODO: needs to be immutable state
  final List<DiveSceneItem> _sceneItems = [];
  List<DiveSceneItem> get sceneItems => _sceneItems;

  DivePointer pointer;

  static Future<DiveScene> create(String name) async {
    if (_sceneCount > 0) {
      throw UnsupportedError('multiple scenes are not supported.');
    }
    _sceneCount++;

    final scene = DiveScene();
    scene.pointer = await obslib.createScene(scene.trackingUUID, name);

    return scene;
  }

  /// Add a source to a scene.
  /// Returns a new scene item.
  Future<DiveSceneItem> addSource(DiveSource source) async {
    final item = obslib.sceneAddSource(pointer, source.pointer);
    final sceneItem = DiveSceneItem(item: item, source: source, scene: this);
    _sceneItems.add(sceneItem);
    return sceneItem;
  }

  /// Finds the scene item for source in this scene.
  DiveSceneItem findSceneItem(DiveSource source) {
    return _sceneItems.firstWhere((sceneItem) => sceneItem.source == source,
        orElse: () => null);
  }

  /// Remove the item from the scene.
  void removeSceneItem(DiveSceneItem sceneItem) {
    if (_sceneItems.remove(sceneItem)) {
      sceneItem.remove();
    }
  }

  /// Remove all items from the scene.
  void removeAllSceneItems() {
    _sceneItems.forEach((sceneItem) {
      sceneItem.remove();
    });
    _sceneItems.clear();
  }
}

// class DiveStateNotifier<T> extends StateNotifier<T> {
//   DiveStateNotifier(T initialState) : super(initialState);

//   void change(T newState) {
//     state = newState;
//   }
// }
