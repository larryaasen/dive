import 'package:flutter/widgets.dart';
import 'package:dive_core/dive_core.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

/// Dive Example 4 - Streaming
void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Configure globally for all Equatable instances via EquatableConfig
  EquatableConfig.stringify = true;

  // Setup [ProviderContainer] so DiveCore and other modules use the same one
  DiveCore.providerContainer = ProviderContainer();

  print('Dive Example 4');

  DiveExample()..run();
}

class DiveExample {
  final _elements = DiveCoreElements();
  DiveCore _diveCore;
  bool _initialized = false;

  void run() {
    _initialize();
  }

  void _initialize() {
    if (_initialized) return;
    _diveCore = DiveCore();
    _diveCore.setupOBS(DiveCoreResolution.HD);

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
        _elements.updateState((state) => state.currentScene.addSource(source));
      });

      // Create the streaming output
      final output = DiveOutput();
      output.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/<your_key_here>';
      output.serviceKey = '<your_key_here>';
      _elements.updateState((state) => state.streamingOutput = output);

      // Start streaming
      print("Dive example 4: Starting stream.");
      output.start();

      Future.delayed(Duration(seconds: 10), () {
        print("Dive example 4: Stopping stream.");
        output.stop();
      });
    });

    _initialized = true;
  }
}
