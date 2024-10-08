import 'package:dive/dive.dart';

/// Dive Example 1 - Streaming
void main() async {
  configDiveApp();

  await DiveExample().run();
}

class DiveExample {
  final _elements = DiveCoreElements();
  final _diveCore = DiveCore();
  bool _initialized = false;

  Future<void> run() async {
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
        _elements.addAudioSource(source);
        _elements.state.currentScene!.addSource(source);
      }
    });

    // Get the first video input
    final videoInput = DiveInputs.video().last;
    print(videoInput);

    // Create the last video source from the video input
    DiveVideoSource.create(videoInput).then((source) {
      if (source != null) {
        _elements.addVideoSource(source);
        // Add the video source to the scene
        _elements.state.currentScene!.addSource(source);
      }
    });

    // Create the streaming output
    var output = DiveStreamingOutput();

    // YouTube settings
    // Replace this YouTube key with your own. This one is no longer valid.
    // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
    // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

    // Twitch Settings
    // Replace this Twitch key with your own. This one is no longer valid.
    output.serviceKey = 'live_276488556_uIKncv1zAGQ3kz5aVzCvfshg8W4ENC';
    output.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${output.serviceKey}';

    // Update the streaming state object
    _elements.addStreamingOutput(output);

    // Start streaming
    print("Dive Example 1: Starting stream.");
    output.start();

    const streamDuration = 30;
    print('Dive Example 1: Waiting $streamDuration seconds.');

    Future.delayed(const Duration(seconds: streamDuration), () {
      print('Dive Example 1: Stopping stream.');
      output.stop();

      final state = _elements.state;
      // Remove the video and audio sources from the scene
      state.currentScene?.removeAllSceneItems();

      // Remove the video source from the state
      final videoSource = state.videoSources.last;
      // Delete the source resources
      videoSource.dispose();

      // Remove the video source from the state
      final audioSource = state.audioSources.last;
      // Delete the source resources
      audioSource.dispose();

      // Delete the scene resources
      _elements.removeAllScenes();
    });
  }
}
