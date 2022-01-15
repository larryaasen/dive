import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive_core/dive_core.dart';

bool multiCamera = false;

/// Dive Example 11 - Configure Stream
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 11',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Configure Stream Example'),
            actions: <Widget>[
              DiveStreamSettingsButton(elements: _elements),
              DiveOutputButton(elements: _elements),
            ],
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    _elements = widget.elements;
    _diveCore = DiveCore();
    await _diveCore.setupCore(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.currentScene = scene);

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state.videoMixes.add(mix));
      });

      DiveAudioSource.create('main audio').then((source) {
        setState(() {
          _elements.updateState((state) => state.audioSources.add(source));
        });
        _elements.updateState((state) => state.currentScene.addSource(source));

        DiveAudioMeterSource()
          ..create(source: source).then((volumeMeter) {
            setState(() {
              source.volumeMeter = volumeMeter;
            });
          });
      });

      DiveInputs.video().forEach((videoInput) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          _elements.updateState((state) {
            state.videoSources.add(source);
            state.currentScene.addSource(source);
          });
        });
      });

      // Create the streaming output
      final output = DiveOutput();
      _elements.updateState((state) => state.streamingOutput = output);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        state.audioSources.firstWhere((source) => source.volumeMeter != null);
    final volumeMeter =
        volumeMeterSource != null ? volumeMeterSource.volumeMeter : null;

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DiveMeterPreview(
          controller: state.videoMixes[0].controller,
          volumeMeter: volumeMeter,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          elements.updateState((state) {
            final source = state.videoSources[newIndex];
            final sceneItem = state.currentScene.findSceneItem(source);
            if (sceneItem != null) {
              sceneItem.setOrder(DiveSceneItemMovement.MOVE_TOP);
            }
          });
          return true;
        });

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
