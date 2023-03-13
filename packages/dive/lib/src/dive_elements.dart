import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_audio_meter_source.dart';
import 'dive_core.dart';
import 'dive_media_source.dart';
import 'dive_streaming_output.dart';
import 'dive_scene.dart';
import 'dive_sources.dart';

class DiveVideoSettingsState extends Equatable {
  const DiveVideoSettingsState();

  @override
  List<Object?> get props => [];
}

class DiveVideoSettings {
  /// Create a Riverpod provider to maintain the state.
  final provider = StateProvider<DiveVideoSettingsState>((ref) => const DiveVideoSettingsState());

  /// Update the state.
  void updateState(DiveVideoSettingsState newState) {
    final notifier = DiveCore.providerContainer.read(provider.notifier);
    if (notifier.state != newState) {
      notifier.state = newState;
    }
  }

  /// Initialize this service.
  void initialize() async {}
}

/// The state model for core elements.
class DiveCoreElementsState extends Equatable {
  // TODO: change all List to Iterable to make these lists immutable.
  final List<DiveAudioSource> audioSources;
  final List<DiveImageSource> imageSources;
  final List<DiveMediaSource> mediaSources;
  final List<DiveVideoSource> videoSources;
  final List<DiveSource> sources;
  final Iterable<DiveScene> scenes;
  final List<DiveVideoMix> videoMixes;
  final DiveStreamingOutput? streamingOutput;
  final DiveScene? currentScene;

  const DiveCoreElementsState(
      {List<DiveAudioSource>? audioSources,
      List<DiveImageSource>? imageSources,
      List<DiveMediaSource>? mediaSources,
      List<DiveVideoSource>? videoSources,
      List<DiveSource>? sources,
      Iterable<DiveScene>? scenes,
      List<DiveVideoMix>? videoMixes,
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
    List<DiveAudioSource>? audioSources,
    List<DiveImageSource>? imageSources,
    List<DiveMediaSource>? mediaSources,
    List<DiveVideoSource>? videoSources,
    List<DiveSource>? sources,
    Iterable<DiveScene>? scenes,
    List<DiveVideoMix>? videoMixes,
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
        streamingOutput,
        currentScene,
      ];

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;
  //   final listEquals = const DeepCollectionEquality().equals;

  //   return other is DiveCoreElementsState &&
  //       listEquals(other.audioSources, audioSources) &&
  //       listEquals(other.imageSources, imageSources) &&
  //       listEquals(other.mediaSources, mediaSources) &&
  //       listEquals(other.videoSources, videoSources) &&
  //       listEquals(other.scenes, scenes) &&
  //       listEquals(other.sources, sources) &&
  //       listEquals(other.videoMixes, videoMixes) &&
  //       other.streamingOutput == streamingOutput &&
  //       other.currentScene == currentScene;
  // }

  // @override
  // int get hashCode {
  //   return audioSources.hashCode ^
  //       imageSources.hashCode ^
  //       mediaSources.hashCode ^
  //       videoSources.hashCode ^
  //       scenes.hashCode ^
  //       sources.hashCode ^
  //       videoMixes.hashCode ^
  //       streamingOutput.hashCode ^
  //       currentScene.hashCode;
  // }
}

/// The core elements used in a Dive app.
class DiveCoreElements {
  /// Create a Riverpod provider to maintain the state.
  final provider = StateProvider<DiveCoreElementsState>((ref) => const DiveCoreElementsState());

  /// Remove a source.
  void removeSource(DiveSource source, List<DiveSource> sources) {
    final item = state.currentScene!.findSceneItem(source);
    if (item != null) {
      final state = DiveCore.container.read(provider.notifier).state;
      state.currentScene!.removeSceneItem(item);
      sources.remove(source);
      source.dispose();
      DiveCore.container.read(provider.notifier).state = state;
    }
  }

  /// Remove iamge source from the current scene.
  void removeImageSource(DiveImageSource source) => removeSource(source, state.imageSources);

  /// Remove media source from the current scene.
  void removeMediaSource(DiveMediaSource source) => removeSource(source, state.mediaSources);

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

        updateState((state) => state.copyWith(mediaSources: state.mediaSources.toList()..add(source)));
        state.currentScene?.addSource(source);
      }
    });
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
}
