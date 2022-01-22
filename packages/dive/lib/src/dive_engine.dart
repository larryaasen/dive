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
  final DiveStream? textInput1;

  DiveCompositingEngine(
      {String? name,
      required this.frameInput1,
      required this.frameInput2,
      this.textInput1,
      DiveCoreProperties? properties})
      : super(name: name, properties: properties);

  @override
  DiveStream get frameOutput => _outputController.stream;

  final _outputController = StreamController<DiveDataStreamItem>.broadcast();

  DiveDataStreamItem? _lastStreamItem1;
  DiveDataStreamItem? _lastStreamItem2;
  DiveDataStreamItem? _lastTextItem;

  /// Start the engine.
  @override
  bool start() {
    onData1(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        Uint8List fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveCompositingEngine.onData1: ($name) input bytes count: ${fileBytes.length}");

        _lastStreamItem1 ??= item;
      }
      _mixAndOutput();
    }

    onData2(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        Uint8List fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveCompositingEngine.onData2: ($name) input bytes count: ${fileBytes.length}");

        _lastStreamItem2 ??= item;
      }
      _mixAndOutput();
    }

    int frameCount = 0;
    Stopwatch? stopwatch;
    onData3(DiveDataStreamItem item) {
      if (item.type == DiveSourceOutputType.text && item.text != null) {
        _lastTextItem = item;
        frameCount++;
        if (stopwatch == null) {
          stopwatch = Stopwatch()..start();
        } else {
          if (stopwatch!.elapsedMilliseconds > 1000) {
            DiveLog.message("text fps: $frameCount");
            stopwatch = Stopwatch()..start();
            frameCount = 0;
          }
        }
      }
      _mixAndOutput();
    }

    void onError(error) {
      DiveLog.message('DiveCompositingEngine.onError: $error');
    }

    frameInput1.listen(onData1, onError: onError);
    frameInput2.listen(onData2, onError: onError);
    textInput1?.listen(onData3, onError: onError);

    DiveLog.message('DiveCompositingEngine.start: ($name) started');
    return true;
  }

  void _mixAndOutput() {
    final newItem = _mixItems();
    if (newItem != null) {
      _outputController.add(newItem);
      // DiveLog.message("DiveCompositingEngine.onData: ($name) added frame");
    }
  }

  DiveDataStreamItem? _mixItems() {
    int width = 1280;
    int height = 720;
    imglib.Image baseImage = DiveLog.timeIt('createBaseImage', () {
      return _createBaseImage(width, height);
    });

    if (_lastStreamItem1 != null && _lastStreamItem1?.frame is DiveFrame) {
      final frame = DiveLog.timeIt('copyResize1', () {
        return imglib.copyResize(_lastStreamItem1!.frame!.image, width: 500);
      });
      baseImage = DiveLog.timeIt('copyInto1', () {
        return imglib.copyInto(baseImage, frame, dstX: 10, dstY: 10);
      });
    }
    if (_lastStreamItem2 != null && _lastStreamItem2?.frame is DiveFrame) {
      final frame = DiveLog.timeIt('copyResize2', () {
        return imglib.copyResize(_lastStreamItem2!.frame!.image, width: 600);
      });
      baseImage = DiveLog.timeIt('copyInto2', () {
        return imglib.copyInto(baseImage, frame, dstX: 520, dstY: 10);
      });
    }

    if (_lastTextItem != null) {
      final text = _lastTextItem!.text;
      baseImage = DiveLog.timeIt('drawString', () {
        return imglib.drawString(
            baseImage, imglib.arial_48, 100, 600, text ?? '',
            color: colorBlue);
      });
    }

    final bytes = DiveLog.timeIt('encodePng', () {
      return Uint8List.fromList(imglib.encodePng(baseImage));
    });
    return DiveDataStreamItem(
        frame: DiveFrame(
      bytes: bytes,
      width: baseImage.width,
      height: baseImage.height,
    ));
  }

  imglib.Image _createBaseImage(int width, int height) {
    final image = imglib.Image.rgb(width, height);
    image.fillBackground(colorRed);
    return image;
  }

  static int get colorRed => imglib.getColor(255, 0, 0);
  static int get colorGreen => imglib.getColor(0, 255, 0);
  static int get colorBlue => imglib.getColor(0, 0, 255);
}
