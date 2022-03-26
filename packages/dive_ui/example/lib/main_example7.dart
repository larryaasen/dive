import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 7 - Audio Inputs
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 7',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Audio Inputs Example'),
          ),
          body: BodyWidget(elements: _elements),
        ));
  }
}

class BodyWidget extends StatefulWidget {
  BodyWidget({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  DiveCore _diveCore;
  DiveCoreElements _elements;
  bool _initialized = false;

  void _initialize() async {
    if (_initialized) return;

    _elements = widget.elements;
    _diveCore = DiveCore();
    await _diveCore.setupOBS(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.currentScene = scene);

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state.videoMixes.add(mix));
      });

      DiveInputs.audio().forEach((audioInput) {
        DiveAudioSource.create("audio", input: audioInput).then((source) {
          print("created audio source: ${audioInput.id}");
          _elements.updateState((state) {
            state.audioSources.add(source);
            state.currentScene.addSource(source);
            DiveAudioMeterSource()
              ..create(source: source).then((volumeMeter) {
                source.volumeMeter = volumeMeter;
              });
          });
        });
      });

      DiveInputs.video().forEach((videoInput) {
        if (videoInput.name.contains('C920')) {
          print(videoInput);
          DiveVideoSource.create(videoInput).then((source) {
            _elements.updateState((state) => state.videoSources.add(source));
            _elements.updateState((state) => state.currentScene.addSource(source));
          });
        }
      });
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    return MediaPlayer(context: context, elements: _elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({
    Key key,
    @required this.elements,
    @required this.context,
  }) : super(key: key);

  final DiveCoreElements elements;
  final BuildContext context;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final state = watch(elements.stateProvider.state);
    if (state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final volumeMeterSource =
        state.audioSources.firstWhere((source) => source.volumeMeter != null, orElse: () => null);
    final volumeMeter = volumeMeterSource != null ? volumeMeterSource.volumeMeter : null;

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DiveMeterPreview(
          controller: state.videoMixes[0].controller,
          volumeMeter: volumeMeter,
          meterVertical: true,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final audios = DiveAudioList(elements: elements, state: state);

    final mainContent = Row(
      children: [
        if (state.audioSources.length > 0) audios,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
