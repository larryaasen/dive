import 'package:dive_core/dive_core.dart';

/// Dive Example 4 - Streaming
void main() async {
  runDiveApp();

  print('Dive Example 4');

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
    await _diveCore.setupCore(DiveCoreResolution.HD);

    // Create the main scene
    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.currentScene = scene);

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
      output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
      output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';
      _elements.updateState((state) => state.streamingOutput = output);

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

          _diveCore = null;
        });
      });
    });
  }
}
