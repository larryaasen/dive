import 'dart:io';

import 'package:dive/dive.dart';

/// Dive Example
void main() async {
  configDiveApp();

  print('Dive Example');

  var n = 0;
  ProcessSignal.sigint.watch().listen((signal) {
    print(" caught ${++n} of 3");

    if (n == 3) {
      exit(0);
    }
  });

  await DiveExample()
    ..run();
}

class DiveExample {
  final _elements = DiveCoreElements();
  final _diveCore = DiveCore();
  bool _initialized = false;

  void run() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    _elements.addScene(DiveScene.create());

    // Create the main audio source
    DiveAudioSource.create('main audio').then((source) {
      if (source != null) {
        _elements.updateState((state) => state..audioSources.add(source));
        _elements.updateState((state) => state..currentScene?.addSource(source));
      }
    });

    // Get the first video input
    final videoInput = DiveInputs.video().last;
    print(videoInput);

    // Create the last video source from the video input
    DiveVideoSource.create(videoInput).then((source) {
      if (source != null) {
        _elements.updateState((state) => state..videoSources.add(source));
        // Add the video source to the scene
        _elements.updateState((state) => state..currentScene?.addSource(source));
      }
    });

    const streamDuration = 5;
    print('Dive example: Waiting $streamDuration seconds.');

    Future.delayed(Duration(seconds: streamDuration), () {
      final state = _elements.state;
      // Remove the video and audio sources from the scene
      state.currentScene?.removeAllSceneItems();

      // Remove the video source from the state
      final videoSource = state.videoSources.removeLast();
      // Delete the source resources
      videoSource.dispose();

      // Remove the video source from the state
      final audioSource = state.audioSources.removeLast();
      // Delete the source resources
      audioSource.dispose();

      // Delete the scene resources
      _elements.removeAllScenes();

      _diveCore.shutdown();
    });
  }
}
