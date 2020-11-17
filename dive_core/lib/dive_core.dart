library dive_core;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class FrameProducer {
  final FrameStream outputStream = FrameStream();
  FrameProducer();
  void addFrame() {
    outputStream.addFrame();
  }
}

class CameraFrameProducer extends FrameProducer {
  CameraFrameProducer();
}

class ImageFrameProducer extends FrameProducer {
  int _instance;
  ImageFrameProducer({FrameStream stream});
  Future<String> loadImage() async {
    final args = {'instance': _instance};
    return await DiveCore.channel
        .invokeMethod('ImageFrameProducer.loadImage', args);
  }
}

class TitlesFrameProducer extends FrameProducer {
  TitlesFrameProducer({FrameStream stream});
  addText(String text) {
    outputStream.addFrame();
  }
}

abstract class FrameConsumer {
  FrameStream stream;
  FrameConsumer({this.stream});
}

class LiveStreamConsumer extends FrameConsumer {
  LiveStreamConsumer(FrameStream stream) : super(stream: stream);

  void startStreaming() {}
  void stopStreaming() {}
}

class RecordStreamConsumer extends FrameConsumer {
  RecordStreamConsumer(FrameStream stream) : super(stream: stream);

  void startRecording() {}
  void stopRecording() {}
}

class FrameStream {
  void addFrame() {}
}

class FrameStreamCombine extends FrameProducer {
  List<FrameStream> inputStreams;
  FrameStreamCombine({this.inputStreams});
}

class FrameStreamUpdate {
  FrameStream inputStream;
  FrameStream outputStream;
  FrameStreamUpdate({this.inputStream, this.outputStream});
}

class FrameMixer extends FrameStreamCombine {
  FrameMixer();
}

class FrameStreamTranslate extends FrameStreamUpdate {
  final int x, y, z;
  FrameStreamTranslate(this.x, this.y, this.z);
}

class LiveStreamDemo {
  liveStreamDemo1() {
    final image = ImageFrameProducer();
    image.loadImage();
    LiveStreamConsumer liveStream = LiveStreamConsumer(image.outputStream);
    liveStream.startStreaming();
  }

  liveStreamDemo2() {
    final imageProducer = ImageFrameProducer();
    imageProducer.loadImage();
    final translater = FrameStreamTranslate(4, 5, 6);
    translater.inputStream = imageProducer.outputStream;

    final camera = CameraFrameProducer();

    final combiner = FrameStreamCombine();
    combiner.inputStreams = [camera.outputStream, translater.outputStream];

    final outputStream = combiner.outputStream;
    LiveStreamConsumer liveStream = LiveStreamConsumer(outputStream);
    liveStream.startStreaming();

    final recording = RecordStreamConsumer(outputStream);
    recording.startRecording();
  }
}

class SourceController extends ValueNotifier<String> {
  SourceController(String value) : super(value ?? "ready");

  /// taken from [CameraController] controller;
}

class SourceAudioController extends SourceController {
  SourceAudioController() : super("ready");
}

class SourceTextureController extends SourceController {
  SourceTextureController() : super("ready");

  int get textureId => _textureId;
  int _textureId;
}

class DiveCore {
  static const MethodChannel _channel = const MethodChannel('dive_core');
  static MethodChannel get channel => _channel;

  static Future<String> get platformVersion async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  static Future<String> get devicesDescription async {
    return await _channel.invokeMethod('getDevicesDescription');
  }

  static Future<List<DiveDevice>> get devices async {
    final List<dynamic> devices = await _channel.invokeMethod('getDevices');
    return devices.map(DiveDevice.fromJson).toList();
  }
}

class DiveDevice {
  final String id;
  final String mediaType;
  final String name;

  DiveDevice({this.id, this.mediaType, this.name});

  static DiveDevice fromJson(dynamic json) {
    return DiveDevice(
      id: json['id'],
      mediaType: json['mediaType'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return "name: $name, id: $id, mediaType: $mediaType";
  }
}
