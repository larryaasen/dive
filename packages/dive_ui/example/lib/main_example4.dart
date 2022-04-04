import 'dart:io';

import 'package:dive/dive.dart';

/// Dive Example 4 - Streaming
void main() async {
  configDiveApp();

  print('Dive Example 4');

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
  DiveCore _diveCore;
  bool _initialized = false;

  void run() async {
    await _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    _diveCore = DiveCore();
    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene
    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.copyWith(currentScene: scene));

      // Create the main audio source
      DiveAudioSource.create('main audio').then((source) {
        _elements.updateState((state) => state.audioSources.add(source));
        _elements.updateState((state) => state.currentScene.addSource(source));
      });

      // Get the first video input
      final videoInput = DiveInputs.video().last;
      print(videoInput);

      // Create the last video source from the video input
      DiveVideoSource.create(videoInput).then((source) {
        _elements.updateState((state) => state.videoSources.add(source));
        // Add the video source to the scene
        _elements.updateState((state) => state.currentScene.addSource(source));
      });

      // Create the streaming output
      var output = DiveOutput();

      // YouTube settings
      // Replace this YouTube key with your own. This one is no longer valid.
      // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
      // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

      // Twitch Settings
      // Replace this Twitch key with your own. This one is no longer valid.
      output.serviceKey = 'live_276488556_uIKncv1zAGQ3kz5aVzCvfshg8W4ENC';
      output.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${output.serviceKey}';

      _elements.updateState((state) => state.copyWith(streamingOutput: output));

      // Start streaming
      print("Dive example 4: Starting stream.");
      output.start();

      const streamDuration = 30;
      print('Dive example 4: Waiting $streamDuration seconds.');

      Future.delayed(Duration(seconds: streamDuration), () {
        print('Dive example 4: Stopping stream.');
        output.stop();
        output = null;

        _elements.updateState((state) {
          // Remove the video and audio sources from the scene
          state.currentScene.removeAllSceneItems();

          // Remove the video source from the state
          final videoSource = state.videoSources.removeLast();
          // Delete the source resources
          videoSource.dispose();

          // Remove the video source from the state
          final audioSource = state.audioSources.removeLast();
          // Delete the source resources
          audioSource.dispose();

          // Delete the scene resources
          scene.dispose();

          _diveCore.shutdown();

          _diveCore = null;
        });
      });
    });
  }
}
