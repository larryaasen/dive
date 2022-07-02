import 'package:collection/collection.dart';
import 'package:dive/dive.dart';
import 'package:riverpod/riverpod.dart';

class DiveVideoSettingsState {}

class _DiveVideoSettingsStateNotifier extends StateNotifier<DiveVideoSettingsState> {
  DiveVideoSettingsState get stateModel => state;

  _DiveVideoSettingsStateNotifier(DiveCoreElementsState stateModel)
      : super(stateModel ?? DiveVideoSettingsState());

  void updateState(DiveVideoSettingsState stateModel) => state = stateModel;
}

class DiveVideoSettings {
  final stateProvider =
      StateNotifierProvider<_DiveVideoSettingsStateNotifier>((ref) => _DiveVideoSettingsStateNotifier(null));
}

/// The state model for core elements.
class DiveCoreElementsState {
  // TODO: Make the class DiveCoreElementsState immutable
  final List<DiveAudioSource> audioSources;
  final List<DiveImageSource> imageSources;
  final List<DiveMediaSource> mediaSources;
  final List<DiveVideoSource> videoSources;
  final List<DiveSource> sources;
  final List<DiveVideoMix> videoMixes;
  final DiveOutput streamingOutput;
  final DiveScene currentScene;

  DiveCoreElementsState(
      {List<DiveAudioSource> audioSources,
      List<DiveImageSource> imageSources,
      List<DiveMediaSource> mediaSources,
      List<DiveVideoSource> videoSources,
      List<DiveSource> sources,
      List<DiveVideoMix> videoMixes,
      this.streamingOutput,
      this.currentScene})
      : audioSources = audioSources ?? [],
        imageSources = imageSources ?? [],
        mediaSources = mediaSources ?? [],
        videoSources = videoSources ?? [],
        sources = sources ?? [],
        videoMixes = videoMixes ?? [];

  /// Updates the current state with only the arguments that are not null.
  DiveCoreElementsState copyWith({
    List<DiveAudioSource> audioSources,
    List<DiveImageSource> imageSources,
    List<DiveMediaSource> mediaSources,
    List<DiveVideoSource> videoSources,
    List<DiveSource> sources,
    List<DiveVideoMix> videoMixes,
    DiveOutput streamingOutput,
    DiveScene currentScene,
  }) {
    return DiveCoreElementsState(
      audioSources: audioSources ?? this.audioSources,
      imageSources: imageSources ?? this.imageSources,
      mediaSources: mediaSources ?? this.mediaSources,
      videoSources: videoSources ?? this.videoSources,
      sources: sources ?? this.sources,
      videoMixes: videoMixes ?? this.videoMixes,
      streamingOutput: streamingOutput ?? this.streamingOutput,
      currentScene: currentScene ?? this.currentScene,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is DiveCoreElementsState &&
        listEquals(other.audioSources, audioSources) &&
        listEquals(other.imageSources, imageSources) &&
        listEquals(other.mediaSources, mediaSources) &&
        listEquals(other.videoSources, videoSources) &&
        listEquals(other.sources, sources) &&
        listEquals(other.videoMixes, videoMixes) &&
        other.streamingOutput == streamingOutput &&
        other.currentScene == currentScene;
  }

  @override
  int get hashCode {
    return audioSources.hashCode ^
        imageSources.hashCode ^
        mediaSources.hashCode ^
        videoSources.hashCode ^
        sources.hashCode ^
        videoMixes.hashCode ^
        streamingOutput.hashCode ^
        currentScene.hashCode;
  }
}

class _DiveCoreElementsStateNotifier extends StateNotifier<DiveCoreElementsState> {
  DiveCoreElementsState get stateModel => state;

  _DiveCoreElementsStateNotifier(DiveCoreElementsState stateModel)
      : super(stateModel ?? DiveCoreElementsState());

  void updateState(DiveCoreElementsState stateModel) {
    state = identical(state, stateModel) ? stateModel.copyWith() : stateModel;
  }
}

/// The core elements used in a Dive app.
class DiveCoreElements {
  final stateProvider =
      StateNotifierProvider<_DiveCoreElementsStateNotifier>((ref) => _DiveCoreElementsStateNotifier(null));

  /// Remove a source.
  void removeSource(DiveSource source, List<DiveSource> sources) {
    final item = state.currentScene.findSceneItem(source);
    if (item != null) {
      final state = DiveCore.notifierFor(stateProvider).stateModel;
      state.currentScene.removeSceneItem(item);
      sources.remove(source);
      source.dispose();
      DiveCore.notifierFor(stateProvider).updateState(state);
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
        final state = DiveCore.notifierFor(stateProvider).stateModel;
        state.imageSources.add(source);
        state.currentScene.addSource(source).then((item) {
          DiveCore.notifierFor(stateProvider).updateState(state);
        });
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
        DiveAudioMeterSource().create(source: source).then((volumeMeter) {
          source.volumeMeter = volumeMeter;
        });

        updateState((state) => state
          ..mediaSources.add(source)
          ..currentScene.addSource(source));
      }
    });
  }

  /// The current state. Changes to this state do not get saved and are not
  /// sent to notifiers. To change the state, use [updateState].
  DiveCoreElementsState get state => DiveCore.notifierFor(stateProvider).stateModel;

  /// Update the current state. Changes to this state are saved and are
  /// sent to notifiers. This method is good for makeing many state
  /// changes, and then having only one change sent the notifiers.
  void updateState(DiveCoreElementsState Function(DiveCoreElementsState state) changeState) {
    final state = DiveCore.notifierFor(stateProvider).stateModel;
    final newState = changeState(state);
    DiveCore.notifierFor(stateProvider).updateState(newState);
  }
}
