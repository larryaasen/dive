import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_app_settings.dart';
import 'dive_audio_meter_source.dart';
import 'dive_core.dart';
import 'dive_media_source.dart';
import 'dive_recording_output.dart';
import 'dive_streaming_output.dart';
import 'dive_scene.dart';
import 'dive_sources.dart';

/// The state model for core elements.
class DiveCoreElementsState extends Equatable {
  final Iterable<DiveAudioSource> audioSources;
  final Iterable<DiveImageSource> imageSources;
  final Iterable<DiveMediaSource> mediaSources;
  final Iterable<DiveVideoSource> videoSources;
  final Iterable<DiveSource> sources;
  final Iterable<DiveScene> scenes;
  final Iterable<DiveVideoMix> videoMixes;
  final DiveRecordingOutput? recordingOutput;
  final DiveStreamingOutput? streamingOutput;
  final DiveScene? currentScene;

  const DiveCoreElementsState(
      {Iterable<DiveAudioSource>? audioSources,
      Iterable<DiveImageSource>? imageSources,
      Iterable<DiveMediaSource>? mediaSources,
      Iterable<DiveVideoSource>? videoSources,
      Iterable<DiveSource>? sources,
      Iterable<DiveScene>? scenes,
      Iterable<DiveVideoMix>? videoMixes,
      this.recordingOutput,
      this.streamingOutput,
      this.currentScene})
      : audioSources = audioSources ?? const [],
        imageSources = imageSources ?? const [],
        mediaSources = mediaSources ?? const [],
        videoSources = videoSources ?? const [],
        sources = sources ?? const [],
        scenes = scenes ?? const [],
        videoMixes = videoMixes ?? const [];

  /// Updates the current state with only the arguments that are not null.
  DiveCoreElementsState copyWith({
    Iterable<DiveAudioSource>? audioSources,
    Iterable<DiveImageSource>? imageSources,
    Iterable<DiveMediaSource>? mediaSources,
    Iterable<DiveVideoSource>? videoSources,
    Iterable<DiveSource>? sources,
    Iterable<DiveScene>? scenes,
    Iterable<DiveVideoMix>? videoMixes,
    DiveRecordingOutput? recordingOutput,
    DiveStreamingOutput? streamingOutput,
    DiveScene? currentScene,
  }) {
    return DiveCoreElementsState(
      audioSources: audioSources ?? this.audioSources,
      imageSources: imageSources ?? this.imageSources,
      mediaSources: mediaSources ?? this.mediaSources,
      videoSources: videoSources ?? this.videoSources,
      sources: sources ?? this.sources,
      scenes: scenes ?? this.scenes,
      videoMixes: videoMixes ?? this.videoMixes,
      recordingOutput: recordingOutput ?? this.recordingOutput,
      streamingOutput: streamingOutput ?? this.streamingOutput,
      currentScene: currentScene ?? this.currentScene,
    );
  }

  DiveCoreElementsState clear({
    bool audioSources = false,
    bool imageSources = false,
    bool mediaSources = false,
    bool videoSources = false,
    bool sources = false,
    bool scenes = false,
    bool videoMixes = false,
    bool recordingOutput = false,
    bool streamingOutput = false,
    bool currentScene = false,
  }) {
    return DiveCoreElementsState(
      audioSources: audioSources ? null : this.audioSources,
      imageSources: imageSources ? null : this.imageSources,
      mediaSources: mediaSources ? null : this.mediaSources,
      videoSources: videoSources ? null : this.videoSources,
      sources: sources ? null : this.sources,
      scenes: scenes ? null : this.scenes,
      videoMixes: videoMixes ? null : this.videoMixes,
      recordingOutput: recordingOutput ? null : this.recordingOutput,
      streamingOutput: streamingOutput ? null : this.streamingOutput,
      currentScene: currentScene ? null : this.currentScene,
    );
  }

  @override
  List<Object?> get props => [
        audioSources,
        imageSources,
        mediaSources,
        videoSources,
        sources,
        scenes,
        videoMixes,
        recordingOutput,
        streamingOutput,
        currentScene,
      ];
}

/// The core elements used in a Dive app.
class DiveCoreElements {
  DiveCoreElements();

  // Optional app settings that will be saved on each state update.
  DiveAppSettingsNode? _appSettings;
  set appSettings(DiveAppSettingsNode node) => _appSettings = node;

  /// Create a Riverpod provider to maintain the state.
  final provider = StateProvider<DiveCoreElementsState>((ref) => const DiveCoreElementsState());

  /// Remove a source.
  void removeSource(DiveSource source, Iterable<DiveSource> sources) {
    final state = DiveCore.container.read(provider.notifier).state;
    if (state.currentScene == null) return;
    final item = state.currentScene?.findSceneItem(source);
    if (item != null) {
      state.currentScene?.removeSceneItem(item);
      final newState = state.copyWith(sources: sources.toList()..remove(source));
      source.dispose();
      DiveCore.container.read(provider.notifier).state = newState;
    }
  }

  /// Remove iamge source from the current scene.
  void removeImageSource(DiveImageSource source) => removeSource(source, state.imageSources);

  /// Remove media source from the current scene.
  void removeMediaSource(DiveMediaSource source) => removeSource(source, state.mediaSources);

  /// Change the current scene to this [scene].
  void changeCurrentScene(DiveScene scene) {
    scene.makeCurrentScene();
    updateState((state) => state.copyWith(currentScene: scene));
  }

  /// Remove all scense disposing of them first, and clear the current scene.
  void removeAllScenes() {
    // Clear the current scene.
    updateState((state) => state.clear(currentScene: true));

    // Dispose of all scenes.
    state.scenes.map((scene) => scene.dispose());

    // Remove all scenes.
    updateState((state) => state.clear(scenes: true));
  }

  /// The current state. Changes to this state do not get saved and are not
  /// sent to notifiers. To change the state, use [updateState].
  DiveCoreElementsState get state => DiveCore.container.read(provider.notifier).state;

  /// Update the current state. Changes to this state are saved and are
  /// sent to notifiers. This method is good for making many state
  /// changes, and then having only one change sent the notifiers.
  void updateState(DiveCoreElementsState Function(DiveCoreElementsState state) onChangeState) {
    final controller = DiveCore.container.read(provider.notifier);
    final currentState = controller.state;
    final newState = onChangeState(currentState);
    final isEqual = newState == currentState;
    assert(!isEqual, 'why are these states equal?');
    controller.state = newState;
  }

  /// Save the current state to app settings.
  void saveAppSettings() {
    final controller = DiveCore.container.read(provider.notifier);
    final elementState = controller.state;
    _saveAppSettings(elementState);
  }

  /// Save the state to app settings.
  void _saveAppSettings(DiveCoreElementsState newState) {
    if (_appSettings == null) return;
    if (newState.recordingOutput != null) {
      _appSettings?.settings['recording'] = newState.recordingOutput!.toMap();
    }
    if (newState.streamingOutput != null) {
      _appSettings?.settings['streaming'] = newState.streamingOutput!.toMap();
    }
    _appSettings?.saveSettings();
  }
}

extension DiveCoreElementsAdd on DiveCoreElements {
  // Add an audio source.
  void addAudioSource(DiveAudioSource source) {
    updateState((state) => state.copyWith(audioSources: state.audioSources.toList()..add(source)));
  }

  /// Add an image source.
  void addImageSource(final localFile) {
    if (state.currentScene == null) {
      throw AssertionError('currentScene must not be null');
    }
    DiveImageSource.create(localFile).then((source) {
      if (source != null) {
        updateState((state) => state.copyWith(imageSources: state.imageSources.toList()..add(source)));
        state.currentScene?.addSource(source);
      }
    });
  }

  /// Add a local video media source to the current scene.
  void addLocalVideoMediaSource(String name, String localFile) {
    if (state.currentScene == null) {
      throw AssertionError('currentScene must not be null');
    }
    final settings = DiveMediaSourceSettings(localFile: localFile, isLocalFile: true);
    DiveMediaSource.create(settings: settings).then((source) {
      if (source != null) {
        source.monitoringType = DiveCoreMonitoringType.monitorAndOutput;
        DiveAudioMeterSource.create(source: source).then((volumeMeter) {
          source.volumeMeter = volumeMeter;
        });
        addMediaSource(source);
        state.currentScene?.addSource(source);
      }
    });
  }

  void addMediaSource(DiveMediaSource source) {
    updateState((state) => state.copyWith(mediaSources: state.mediaSources.toList()..add(source)));
  }

  /// Add a video mix.
  void addMix(DiveVideoMix mix) {
    updateState((state) => state.copyWith(videoMixes: state.videoMixes.toList()..add(mix)));
  }

  /// Add recording output.
  void addRecordingOutput(DiveRecordingOutput output) {
    updateState((state) => state.copyWith(recordingOutput: output));
  }

  /// Add a scene and set it as the [currentScene] if null.
  DiveScene addScene(DiveScene scene) {
    updateState((state) {
      return state.copyWith(scenes: state.scenes.toList()..add(scene));
    });
    if (state.currentScene == null) {
      updateState((state) => state.copyWith(currentScene: scene));
    }
    return scene;
  }

  // Add a source.
  void addSource(DiveSource source) {
    updateState((state) => state.copyWith(sources: state.sources.toList()..add(source)));
  }

  /// Add streaming output.
  void addStreamingOutput(DiveStreamingOutput output) {
    updateState((state) => state.copyWith(streamingOutput: output));
  }

  /// Add a video source.
  void addVideoSource(DiveVideoSource source) {
    updateState((state) => state.copyWith(videoSources: state.videoSources.toList()..add(source)));
  }
}
