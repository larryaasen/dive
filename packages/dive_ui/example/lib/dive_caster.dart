import 'package:dive/dive.dart';
import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/widgets.dart';

/// Dive Caster Multi Camera Streaming and Recording
Future<void> main() async {
  // We need the binding to be initialized before calling runApp
  WidgetsFlutterBinding.ensureInitialized();

  final appMain = DiveCasterMain();
  await appMain.initialize();

  runDiveUIApp(DiveCasterApp(elements: appMain.elements));
}

class DiveCasterMain {
  DiveCore get core => _diveCore;
  DiveCoreElements get elements => _elements;

  final _diveCore = DiveCore();
  final _elements = DiveCoreElements();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Setup and start OBS.
    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    elements.addScene(DiveScene.create());

    DiveVideoMix.create().then((mix) {
      if (mix != null) elements.addMix(mix);
    });

    DiveAudioSource.create('main audio').then((source) {
      if (source != null) {
        elements.addAudioSource(source);
        elements.state.currentScene?.addSource(source);

        DiveAudioMeterSource.create(source: source).then((volumeMeter) {
          source.volumeMeter = volumeMeter;
        });
      }
    });

    DiveInputs.video().forEach((videoInput) {
      print(videoInput);
      DiveVideoSource.create(videoInput).then((source) {
        if (source != null) {
          elements.addVideoSource(source);
          elements.state.currentScene?.addSource(source);
        }
      });
    });

    // Create the recording output
    final recordingOutput = DiveRecordingOutput();
    elements.addRecordingOutput(recordingOutput);

    // // Create the streaming output
    // final streamingOutput = DiveStreamingOutput();

    // // YouTube settings
    // // Replace this YouTube key with your own. This one is no longer valid.
    // // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
    // // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

    // // Twitch Settings
    // // Replace this Twitch key with your own. This one is no longer valid.
    // streamingOutput.serviceKey = '-----';
    // streamingOutput.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${streamingOutput.serviceKey}';

    // elements.addStreamingOutput(streamingOutput);

    // // Create the recording output
    // final recordingOutput = DiveRecordingOutput();
    // elements.addRecordingOutput(recordingOutput);

    // // Start recording.
    // recordingOutput.start('/Users/larry/Movies/dive/dive1.mkv');
  }
}
