import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'dive_audio_meter_source.dart';
import 'dive_input.dart';
import 'dive_input_provider.dart';
import 'dive_input_type.dart';
import 'dive_properties.dart';
import 'dive_scene.dart';
import 'dive_system_log.dart';
import 'dive_tracking.dart';
import 'dive_transform_info.dart';

// TODO: move this or remove this annotation
class _MustCallSuper {
  const _MustCallSuper();
}

/// Used to annotate an instance method `m`. Indicates that every invocation of
/// a method that overrides `m` must also invoke `m`. In addition, every method
/// that overrides `m` is implicitly annotated with this same annotation.
///
/// Note that private methods with this annotation cannot be validly overridden
/// outside of the library that defines the annotated method.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance method,
///   or
/// * a method that overrides a method that has this annotation can return
///   without invoking the overridden method.
const _MustCallSuper mustCallSuper = _MustCallSuper();

class DiveVideoMix extends DiveTracking {
  DiveVideoMix();

  static Future<DiveVideoMix> create() async {
    final video = DiveVideoMix();
    return video;
  }
}

abstract class DiveSource extends DiveTracking {
  final DiveInputType inputType;
  final String? name;
  final DiveCoreProperties? properties;
  dynamic pointer;
  List<DiveSourceOutput> outputs = [];
  List<DiveSourceController> controllers = [];

  Stream<DiveDataStreamItem> get frameOutput;

  DiveSource({required this.inputType, this.name, this.properties});

  @override
  String toString() {
    return "$runtimeType($hashCode, $name)";
  }

  @mustCallSuper
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

    DiveLog.message("DiveAudioSource.create: device_id=$deviceId");

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
  Stream<DiveDataStreamItem> get frameOutput => throw UnimplementedError();
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
  Stream<DiveDataStreamItem> get frameOutput => throw UnimplementedError();
}

class DiveImageSource extends DiveSource {
  DiveDataStreamItem? _lastStreamItem;
  bool _loadingLastStreamItem = false;

  @override
  Stream<DiveDataStreamItem> get frameOutput => _outputStream();

  DiveImageSource._({String? name, DiveCoreProperties? properties})
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
  factory DiveImageSource.create(
      {String? name, DiveCoreProperties? properties}) {
    final source = DiveImageSource._(name: name, properties: properties);
    return source;
  }

  Stream<DiveDataStreamItem> _outputStream() {
    StreamController<DiveDataStreamItem>? controller;

    Future<void> onListen() async {
      DiveLog.message("DiveImageSource: outputStream: onListen");
      if (_lastStreamItem != null) {
        controller?.add(_lastStreamItem!);
        return;
      }
      if (properties != null && !_loadingLastStreamItem) {
        final filename =
            properties!.getString(DiveImageInputProvider.PROPERTY_FILENAME);
        if (filename != null && filename.isNotEmpty) {
          final file = File(filename);
          _loadingLastStreamItem = true;
          file.exists().then((exists) {
            if (exists && controller != null) {
              _readFile(file, controller);
            } else {
              _loadingLastStreamItem = false;
              DiveLog.message(
                  "DiveImageSource: filename does not exist: $filename");
            }
          });
        } else {
          final url =
              properties!.getString(DiveImageInputProvider.PROPERTY_URL);
          if (url != null && url.isNotEmpty && controller != null) {
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
        controller.add(_lastStreamItem!);
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
    http.readBytes(uri).then((fileBytes) {
      _loadingLastStreamItem = false;
      if (fileBytes.isNotEmpty) {
        DiveLog.message("DiveImageSource: file loaded: $url");
        _lastStreamItem = DiveDataStreamItem(data: fileBytes);
        controller.add(_lastStreamItem!);
      }
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

enum DiveSourceOutputType {
  AUDIO,
  DRAWING,
  FRAME,
  TEXT,
}

class DiveSourceOutputConfiguration {}

class DiveSourceFrameConfiguration extends DiveSourceOutputConfiguration {
  final int width;
  final int height;
  DiveSourceFrameConfiguration(this.width, this.height);
}

/// This object is sent to every downstream process of the source. It is sent
/// as one item in the stream.
class DiveDataStreamItem {
  final dynamic data;
  final DiveSourceOutputType? type; // TODO: make this non-optional
  final DiveSourceOutputConfiguration?
      configuration; // TODO: make this non-optional

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
