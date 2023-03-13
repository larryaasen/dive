import 'dart:io';

import 'package:dive/dive.dart';

/// Dive Example 4 - Streaming
void main() async {
  // Configure an app to use Dive with this built in method.
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
  final _diveCore = DiveCore();
  bool _initialized = false;

  void run() {
    _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    _elements.addScene(DiveScene.create());

    // Create the main audio source
    DiveAudioSource.create('main audio').then((source) {
      if (source != null) {
        _elements
            .updateState((state) => state.copyWith(audioSources: state.audioSources.toList()..add(source)));
        _elements.state.currentScene?.addSource(source);
      }
    });

    // Get the first video input
    final videoInput = DiveInputs.video().last;
    print(videoInput);

    // Create the last video source from the video input
    DiveVideoSource.create(videoInput).then((source) {
      if (source != null) {
        _elements
            .updateState((state) => state.copyWith(videoSources: state.videoSources.toList()..add(source)));
        // Add the video source to the scene
        _elements..state.currentScene?.addSource(source);
      }
    });

    // Create the streaming output
    final streamingOutput = DiveStreamingOutput();

    // YouTube settings
    // Replace this YouTube key with your own. This one is no longer valid.
    // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
    // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

    // Twitch Settings
    // Replace this Twitch key with your own. This one is no longer valid.
    streamingOutput.serviceKey = 'live_276488556_ZQRwvdknV8MrOJCaGwquIzM17dQDJ5';
    streamingOutput.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${streamingOutput.serviceKey}';

    _elements.updateState((state) => state.copyWith(streamingOutput: streamingOutput));

    // Start streaming
    print("Dive example 4: Starting stream.");
    streamingOutput.start();

    const streamDuration = 30;
    print('Dive example 4: Waiting $streamDuration seconds.');

    Future.delayed(Duration(seconds: streamDuration), () {
      print('Dive example 4: Stopping stream.');
      streamingOutput.stop();
      streamingOutput.dispose();

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
