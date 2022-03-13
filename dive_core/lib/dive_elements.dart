import 'package:dive_core/dive_core.dart';
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
  final List<DiveAudioSource> audioSources = [];
  final List<DiveImageSource> imageSources = [];
  final List<DiveMediaSource> mediaSources = [];
  final List<DiveVideoSource> videoSources = [];
  final List<DiveVideoMix> videoMixes = [];
  DiveOutput streamingOutput;
  DiveScene currentScene;
}

class _DiveCoreElementsStateNotifier extends StateNotifier<DiveCoreElementsState> {
  DiveCoreElementsState get stateModel => state;

  _DiveCoreElementsStateNotifier(DiveCoreElementsState stateModel)
      : super(stateModel ?? DiveCoreElementsState());

  void updateState(DiveCoreElementsState stateModel) => state = stateModel;
}

/// The core elements used in a Dive app.
class DiveCoreElements {
  final stateProvider =
      StateNotifierProvider<_DiveCoreElementsStateNotifier>((ref) => _DiveCoreElementsStateNotifier(null));

  /// Add an image source.
  void addImageSource(final localFile) {
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

  /// Add a video source.
  void addVideoSource(final localFile) {
    DiveMediaSource.create(localFile).then((source) {
      if (source != null) {
        DiveAudioMeterSource()
          ..create(source: source).then((volumeMeter) {
            source.volumeMeter = volumeMeter;
          });

        final state = DiveCore.notifierFor(stateProvider).stateModel;
        state.mediaSources.add(source);
        state.currentScene.addSource(source);
        DiveCore.notifierFor(stateProvider).updateState(state);
      }
    });
  }

  /// The current state. Changes to this state do not get saved and are not
  /// sent to notifiers. To change the state, use [updateState].
  DiveCoreElementsState get state => DiveCore.notifierFor(stateProvider).stateModel;

  /// Update the current state. Changes to this state are saved and are
  /// sent to notifiers. This method is good for makeing many state
  /// changes, and then having only one change sent the notifiers.
  void updateState(void changeState(DiveCoreElementsState state)) {
    final state = DiveCore.notifierFor(stateProvider).stateModel;
    changeState(state);
    DiveCore.notifierFor(stateProvider).updateState(state);
  }
}
