import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_media_source.dart';
import 'package:dive_core/dive_sources.dart';
import 'package:dive_core/dive_output.dart';
import 'package:riverpod/riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

/// The state model for core elements.
class DiveCoreElementsState {
  final List<DiveAudioSource> audioSources = [];
  final List<DiveImageSource> imageSources = [];
  final List<DiveMediaSource> mediaSources = [];
  final List<DiveVideoSource> videoSources = [];
  final List<DiveVideoMix> videoMixes = [];
  final streamingOutput = DiveOutput();
  DiveScene currentScene;
}

class _DiveCoreElementsStateNotifier
    extends StateNotifier<DiveCoreElementsState> {
  DiveCoreElementsState get stateModel => state;

  _DiveCoreElementsStateNotifier(DiveCoreElementsState stateModel)
      : super(stateModel ?? DiveCoreElementsState());

  void updateState(DiveCoreElementsState stateModel) {
    state = stateModel;
  }
}

class DiveCoreElements {
  final stateProvider = StateNotifierProvider<_DiveCoreElementsStateNotifier>(
      (ref) => _DiveCoreElementsStateNotifier(null));

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
  DiveCoreElementsState get state =>
      DiveCore.notifierFor(stateProvider).stateModel;

  /// Update the current state. Changes to this state are saved and are
  /// sent to notifiers.
  void updateState(void changeState(DiveCoreElementsState state)) {
    final state = DiveCore.notifierFor(stateProvider).stateModel;
    changeState(state);
    DiveCore.notifierFor(stateProvider).updateState(state);
  }
}
