import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as imglib;

import 'dive_properties.dart';
import 'dive_stream.dart';
import 'dive_system_log.dart';
import 'dive_tracking.dart';

/// A [DiveEngine] produces an output stream of frames from an input stream of
/// frames. There are various types of engines such as a compositing, filtering,
/// and audio mixing.
abstract class DiveEngine extends DiveNamedTracking {
  final DiveCoreProperties? properties;

  DiveEngine({String? name, this.properties}) : super(name: name);

  DiveStream get frameOutput;

  /// Start the engine.
  bool start();
}

class DiveCompositingEngine extends DiveEngine {
  final DiveStream frameInput1;
  final DiveStream frameInput2;
  DiveCompositingEngine(
      {String? name,
      required this.frameInput1,
      required this.frameInput2,
      DiveCoreProperties? properties})
      : super(name: name, properties: properties);

  @override
  DiveStream get frameOutput => _outputController.stream;

  final _outputController = StreamController<DiveDataStreamItem>.broadcast();

  DiveDataStreamItem? _lastStreamItem1;
  DiveDataStreamItem? _lastStreamItem2;

  /// Start the engine.
  @override
  bool start() {
    void onData(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        Uint8List fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveCompositingEngine.onData: ($name) input bytes count: ${fileBytes.length}");

        _lastStreamItem1 ??= item;
        _lastStreamItem2 ??= item;

        final newItem = _mixItems();
        if (newItem != null) {
          _outputController.add(newItem);
          DiveLog.message("DiveCompositingEngine.onData: ($name) added frame");
        }
      }
    }

    void onError(error) {
      DiveLog.message('DiveCompositingEngine.onError: $error');
    }

    frameInput1.listen(onData, onError: onError);
    frameInput2.listen(onData, onError: onError);

    DiveLog.message('DiveCompositingEngine.start: ($name) started');
    return true;
  }

  DiveDataStreamItem? _mixItems() {
    int width = 1280;
    int height = 720;
    if (_lastStreamItem1 == null && _lastStreamItem2 == null) {
      return null;
    }
    if (_lastStreamItem1 != null && _lastStreamItem2 != null) {
      if (_lastStreamItem1?.frame is DiveFrame &&
          _lastStreamItem2?.frame is DiveFrame) {
        final newImage = _mixData(_lastStreamItem1!.frame!.image,
            _lastStreamItem2!.frame!.image, width, height);
        return DiveDataStreamItem(
            frame: DiveFrame(
          bytes: Uint8List.fromList(imglib.encodePng(newImage)),
          width: newImage.width,
          height: newImage.height,
        ));
      }
    } else {
      if (_lastStreamItem1 != null) return _lastStreamItem1;
      if (_lastStreamItem2 != null) return _lastStreamItem2;
    }
  }

  imglib.Image _mixData(
      imglib.Image frame1, imglib.Image frame2, int width, int height) {
    imglib.Image baseImage = _createBaseImage(width, height);

    try {
      frame1 = imglib.copyResize(frame1, width: 500);
      frame2 = imglib.copyResize(frame2, width: 600);

      baseImage = imglib.copyInto(baseImage, frame1, dstX: 10, dstY: 10);
      baseImage = imglib.copyInto(baseImage, frame2, dstX: 520, dstY: 10);
    } catch (e) {
      DiveLog.error('DiveEngine error: $e');
      return frame1;
    }
    return baseImage;
  }

  imglib.Image _createBaseImage(int width, int height) {
    final image = imglib.Image.rgb(width, height);
    image.fillBackground(colorRed);
    return image;
  }

  static int get colorRed => imglib.getColor(255, 0, 0);
}
