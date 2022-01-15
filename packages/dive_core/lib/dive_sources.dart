import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'dive_core.dart';
import 'dive_tracking.dart';

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

class DiveVideoMix extends DiveTracking with DiveTextureController {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    await video.setupController(video.trackingUUID);
    return video;
  }
}

abstract class DiveSource extends DiveTracking {
  final DiveInputType inputType;
  final String name;
  final DiveCoreProperties properties;
  dynamic pointer;
  List<DiveSourceOutput> outputs = [];
  List<DiveSourceController> controllers = [];

  Stream get frameOutput;

  DiveSource({this.inputType, this.name, this.properties});

  @override
  String toString() {
    return "${this.runtimeType}(${this.hashCode}, $name)";
  }

  @mustCallSuper
  bool dispose() {
    return true;
  }
}

class DiveTextureSource extends DiveTextureController {
  DiveTextureSource({DiveInputType inputType, String name});
  // : super(inputType: inputType, name: name);
}

class DiveAudioSource extends DiveSource {
  DiveAudioSource({String name, this.input, DiveInputType inputType})
      : super(name: name, inputType: inputType);

  final DiveInput input;
  DiveAudioMeterSource volumeMeter;

  static Future<DiveAudioSource> create(String name, {DiveInput input}) async {
    final source = DiveAudioSource(
        name: name, input: input, inputType: DiveInputType.audio);

    final properties = DiveCoreProperties();
    final deviceId = source.input == null ? "default" : source.input.id;
    properties.setString("device_id", deviceId);

    DiveLog.message("DiveAudioSource.create: device_id=$deviceId");

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

  @override
  // TODO: implement frameStream
  Stream get frameOutput => throw UnimplementedError();
}

/// A video source supports video cameras and other similar devices.
/// This is not a source for playing video files.
class DiveVideoSource extends DiveSource with DiveTextureController {
  DiveAudioMeterSource volumeMeter;

  DiveVideoSource({String name})
      : super(inputType: DiveInputType.video, name: name);

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

  @override
  // TODO: implement frameStream
  Stream get frameOutput => throw UnimplementedError();
}

class DiveImageSource extends DiveSource {
  DiveDataStreamItem _lastStreamItem;
  bool _loadingLastStreamItem = false;

  @override
  Stream get frameOutput => _outputStream();

  DiveImageSource._({String name, DiveCoreProperties properties})
      : super(
            inputType: DiveInputType.image,
            name: name,
            properties: properties) {
    if (properties != null) {
      final filename =
          properties.getString(DiveImageInputProvider.PROPERTY_FILENAME);
      if (filename != null && filename.isNotEmpty) {
        final file = File(filename);
        file.exists().then((exists) {
          if (!exists) {
            DiveLog.message(
                "DiveImageSource: filename does not exist: $filename");
          }
        });
      } else {
        final url = properties.getString(DiveImageInputProvider.PROPERTY_URL);
        if (url != null && url.isNotEmpty) {
          try {
            Uri.parse(url);
          } on Exception catch (e) {
            DiveLog.message("DiveImageSource: url not valid: $url, ${e}");
          }
        }
      }
    }

    // // Setup output stream
    // final output = DiveSourceOutput();
    // output.dataStream = outputStream();
    // outputs.add(output);
  }

  /// Create an image source.
  factory DiveImageSource.create({String name, DiveCoreProperties properties}) {
    final source = DiveImageSource._(name: name, properties: properties);
    return source;
  }

  Stream<DiveDataStreamItem> _outputStream() {
    StreamController<DiveDataStreamItem> controller;

    Future<void> onListen() async {
      DiveLog.message("DiveImageSource: outputStream: onListen");
      if (_lastStreamItem != null) {
        controller.add(_lastStreamItem);
        return;
      }
      if (properties != null && !_loadingLastStreamItem) {
        final filename =
            properties.getString(DiveImageInputProvider.PROPERTY_FILENAME);
        if (filename != null && filename.isNotEmpty) {
          final file = File(filename);
          _loadingLastStreamItem = true;
          file.exists().then((exists) {
            if (exists) {
              _readFile(file, controller);
            } else {
              _loadingLastStreamItem = false;
              DiveLog.message(
                  "DiveImageSource: filename does not exist: $filename");
            }
          });
        } else {
          final url = properties.getString(DiveImageInputProvider.PROPERTY_URL);
          if (url != null && url.isNotEmpty) {
            _readNetworkFile(url, controller);
          }
        }
      }
    }

    controller = StreamController<DiveDataStreamItem>(onListen: onListen);

    return controller.stream;
  }

  void _readFile(File file, StreamController<DiveDataStreamItem> controller) {
    _loadingLastStreamItem = true;
    file.readAsBytes().then((fileBytes) {
      _loadingLastStreamItem = false;
      if (fileBytes.isNotEmpty) {
        DiveLog.message("DiveImageSource: file loaded: $file");
        _lastStreamItem = DiveDataStreamItem(data: fileBytes);
        controller.add(_lastStreamItem);
      }
    });
  }

  void _readNetworkFile(
      String url, StreamController<DiveDataStreamItem> controller) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } on Exception {
      _loadingLastStreamItem = false;
      DiveLog.message("DiveImageSource: file does not exist: $url");
      return;
    }
    _loadingLastStreamItem = true;
    HttpClient client = new HttpClient();
    client.getUrl(uri).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      consolidateHttpClientResponseBytes(response).then((fileBytes) {
        _loadingLastStreamItem = false;
        if (fileBytes.isNotEmpty) {
          DiveLog.message("DiveImageSource: file loaded: $url");
          _lastStreamItem = DiveDataStreamItem(data: fileBytes);
          controller.add(_lastStreamItem);
        }
      });
    });
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
  final dynamic data;
  final DiveSourceOutputType type;
  final DiveSourceOutputConfiguration configuration;

  DiveDataStreamItem({this.data, this.type, this.configuration});
}

/// A source controller that handles actions sent to a source.
class DiveSourceController {
  // actions
}

/// A microphone controller.
class DiveMicrophoneController extends DiveSourceController {}

/// A source output which includes a stream.
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

// class DiveSourceInternal extends DiveTracking {
//   List<DiveSourceOutput> outputs;
//   List<DiveSourceController> controllers;
// }
