import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
    int width = 1280;
    int height = 720;

    onData1(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        Uint8List fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveCompositingEngine.onData1: ($name) input bytes count: ${fileBytes.length}");

        _lastStreamItem1 ??= item;
      }
      _mixAndOutput(width, height);
    }

    onData2(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        Uint8List fileBytes = item.frame!.bytes;
        DiveLog.message(
            "DiveCompositingEngine.onData2: ($name) input bytes count: ${fileBytes.length}");

        _lastStreamItem2 ??= item;
      }
      _mixAndOutput(width, height);
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

      _mixAndOutput(width, height);
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

  void _mixAndOutput(int width, int height) async {
    final image = await _makeImage(width, height);
    final newItem = DiveDataStreamItem(
        frame: DiveFrame(
      bytes: Uint8List(0),
      width: width,
      height: height,
      uiImage: image,
    ));
    _outputController.add(newItem);
  }

  Future<ui.Image> _makeImage6(int width, int height) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    canvas.drawColor(Colors.red, ui.BlendMode.src);

    final paint = ui.Paint()..color = Colors.green;
    canvas.drawRect(
        Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2), paint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(width, height);
    return image;
  }

  Future<ui.Image> _makeImage(int width, int height) async {
    final image = await DiveLog.timeItAsync('_makeImage', () async {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder,
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
      final paint = ui.Paint()..color = Colors.green;
      canvas.drawColor(Colors.red, ui.BlendMode.src);
      _drawText(canvas);

      // canvas.clipRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      if (_lastStreamItem1 != null && _lastStreamItem1!.frame != null) {
        final uiImage = await _lastStreamItem1!.frame!.uiImageLive;
        if (uiImage != null) {
          canvas.save();
          double scale = 4.0 / 10.0;
          double reScale = 10.0 / 4.0;
          canvas.scale(scale);
          canvas.drawImage(uiImage, Offset(10 * reScale, 10 * reScale), paint);
          canvas.restore();
        }
      }

      if (_lastStreamItem2 != null && _lastStreamItem2!.frame != null) {
        final uiImage = await _lastStreamItem2!.frame!.uiImageLive;
        if (uiImage != null) {
          canvas.save();
          double scale = (width.toDouble() / 2.0) / uiImage.width.toDouble();
          double reScale = uiImage.width.toDouble() / (width.toDouble() / 2.0);
          canvas.scale(scale);
          canvas.drawImage(
              uiImage, Offset((width / 2) * reScale, 100 * reScale), paint);
          canvas.restore();
        }
      }

      final picture = pictureRecorder.endRecording();

      // final stopwatch = Stopwatch()..start();
      final image = await picture.toImage(width, height);
      // final elapsed = stopwatch.elapsed;
      // DiveLog.message('toImage elapsed: ${elapsed.inMilliseconds}ms');

      return image;
    });
    return image;
  }

  void _drawText(Canvas canvas) {
    if (_lastTextItem == null || _lastTextItem!.text == null) {
      return;
    }
    final text = _lastTextItem!.text!;
    final textStyle = ui.TextStyle(
      color: Colors.black,
      fontSize: 48,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textDirection: TextDirection.ltr,
    );
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);
    final constraints = ui.ParagraphConstraints(width: 800);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(constraints);
    final offset = Offset(100, 600);
    canvas.drawParagraph(paragraph, offset);
  }

  void _mixAndOutput2(int width, int height) {
    final bytes = _mixItems(width, height);
    final newItem = DiveDataStreamItem(
        frame: DiveFrame(
      bytes: bytes,
      width: width,
      height: height,
    ));

    _outputController.add(newItem);
    // DiveLog.message("DiveCompositingEngine.onData: ($name) added frame");
  }

  Uint8List _mixItems(int width, int height) {
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
    return bytes;
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
