import 'package:dive/dive.dart';
import 'package:dive_ui/dive_caster.dart';
import 'package:dive_ui/dive_ui_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

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

    final applicationSupportDirectory = await getApplicationSupportDirectory();

    // Setup app settings.
    final appSettings =
        DiveAppSettings(directoryPath: applicationSupportDirectory, mainFileName: 'dive_caster_settings.yml');
    final elementsNode = DiveAppSettingsNode(nodeName: 'elements', parentNode: appSettings);
    final windowNode = DiveAppSettingsNode(nodeName: 'window', parentNode: appSettings);
    appSettings.addNode(elementsNode);
    appSettings.addNode(windowNode);
    _elements.appSettings = elementsNode;
    await appSettings.loadSettings();

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

    // Create the streaming output
    final streamingOutput = DiveStreamingOutput();
    streamingOutput.updateFromMap(elementsNode.settings['streaming'] as Map<String, dynamic>? ?? {});

    elements.addStreamingOutput(streamingOutput);
  }
}
