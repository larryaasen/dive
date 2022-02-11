// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dive/dive.dart';
import 'package:flutter/painting.dart';

import 'dive_video_plugin.dart';

final _diveVideoPlugin = DiveVideoPlugin();

/// The standard video input provider.
class DiveVideoInputProvider extends DiveInputProvider {
  /// The input id to be created.
  static const String PROPERTY_INPUT_ID = 'input_id';

  /// Discovers and provides a list of inputs.
  @override
  Future<List<DiveInput>?> inputs() => _getInputs();

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.video];

  /// Create a [DiveSource] for the [input].
  @override
  DiveVideoSource? create(String? name, DiveCoreProperties? properties) {
    return DiveVideoSource.create(name: name, properties: properties);
  }

  Future<List<DiveInput>?> _getInputs() async {
    return _diveVideoPlugin.inputsListFromType(DiveInputType.video);
  }
}

/// A video source supports video cameras and other similar devices.
/// This is not a source for playing media and video files.
class DiveVideoSource extends DiveSource {
  @override
  DiveStream get frameOutput => _outputController.stream;

  DiveAudioMeterSource? volumeMeter;

  final _outputController = StreamController<DiveDataStreamItem>.broadcast();
  dynamic _callbackChannel;

  /// Create a video source.
  factory DiveVideoSource.create(
      {String? name, DiveCoreProperties? properties}) {
    final source = DiveVideoSource._(name: name, properties: properties);
    return source;
  }

  DiveVideoSource._({String? name, DiveCoreProperties? properties})
      : super(
            inputType: DiveInputType.video, name: name, properties: properties);

  Future<bool?> setup() {
    final inputId =
        properties?.getString(DiveVideoInputProvider.PROPERTY_INPUT_ID);
    if (inputId == null) return Future.value(false);
    return DiveVideoInputProvider().inputs().then((inputs) {
      final index = inputs?.indexWhere((element) => element.id == inputId);
      if (index == null || index == -1) return Future.value(false);
      return _diveVideoPlugin
          .createVideoSource(inputs![index], onFrame)
          .then((methodChannel) {
        _callbackChannel = methodChannel;
        return methodChannel != null;
      });
    });
  }

  void onFrame(int width, int height, Uint8List bytes, int linesize) {
    // final item = DiveDataStreamItem(
    //     frame: DiveFrame(
    //   bytes: bytes,
    //   width: width,
    //   height: height,
    // ));
    // _outputController.add(item);
    // return;

    ui.decodeImageFromPixels(
      bytes,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        final item = DiveDataStreamItem(
            frame: DiveFrame(
          bytes: Uint8List(0),
          width: width,
          height: height,
          uiImage: image,
        ));
        _outputController.add(item);
      },
      rowBytes: linesize,
    );
    // ui.ImmutableBuffer.fromUint8List(bytes).then((buffer) {
    //   final descriptor = ui.ImageDescriptor.raw(
    //     buffer,
    //     width: width,
    //     height: height,
    //     pixelFormat: ui.PixelFormat.rgba8888,
    //   );
    //   // buffer.dispose();
    //   descriptor
    //       .instantiateCodec(targetWidth: width, targetHeight: height)
    //       .then((codec) {
    //     // descriptor.dispose();
    //     codec.getNextFrame().then((ui.FrameInfo frameInfo) {
    //       // codec.dispose();
    //       final fImage = frameInfo.image;
    //       // fImage.dispose();
    //       print("image height = ${fImage.height}");
    //     });
    //   });
    // });
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
}
