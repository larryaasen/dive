import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'dive_properties.dart';
import 'dive_stream.dart';
import 'dive_system_log.dart';
import 'dive_tracking.dart';

/// A [DiveEngine] produces an output stream of frames from an input stream of
/// frames. There are various types of engines such as a compositing, filtering,
/// and audio mixing.
abstract class DiveEngine extends DiveNamedTracking {
  final DiveStream frameInput;
  final DiveCoreProperties? properties;

  DiveEngine({String? name, required this.frameInput, this.properties})
      : super(name: name);

  DiveStream get frameOutput;

  /// Start the engine.
  bool start();
}

class DiveCompositingEngine extends DiveEngine {
  DiveCompositingEngine(
      {String? name,
      required DiveStream frameInput,
      DiveCoreProperties? properties})
      : super(name: name, frameInput: frameInput, properties: properties);

  @override
  DiveStream get frameOutput => _outputController.stream;

  StreamController<DiveDataStreamItem> _outputController =
      StreamController<DiveDataStreamItem>.broadcast();

  /// Start the engine.
  @override
  bool start() {
    _outputController = StreamController<DiveDataStreamItem>.broadcast();

    void onData(DiveDataStreamItem item) {
      Uint8List fileBytes = item.data;
      DiveLog.message(
          "DiveCompositingEngine.onData: ($name) input bytes count: ${fileBytes.length}");
      _outputController.add(item);
    }

    frameInput.listen(onData);
    DiveLog.message('DiveCompositingEngine.start: ($name) started');
    return false;
  }
}
