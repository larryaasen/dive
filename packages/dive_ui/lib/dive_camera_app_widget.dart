import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// The Dive Camera App widget, that displays a list of live cameras.
class DiveCameraAppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  DiveCameraAppWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Camera',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          body: DiveCameraAppBody(elements: _elements),
        ));
  }
}

class DiveCameraAppBody extends StatefulWidget {
  DiveCameraAppBody({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _DiveCameraAppBodyState createState() => _DiveCameraAppBodyState();
}

class _DiveCameraAppBodyState extends State<DiveCameraAppBody> {
  DiveCore _diveCore;
  DiveCoreElements _elements;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _elements = widget.elements;
    _diveCore = DiveCore();
    _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.copyWith(currentScene: scene));

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state..videoMixes.add(mix));
      });

      DiveInputs.video().forEach((videoInput) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          _elements.updateState((state) => state
            ..videoSources.add(source)
            ..currentScene.addSource(source));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DiveCameraAppMediaPlayer(context: context, elements: _elements);
  }
}

class DiveCameraAppMediaPlayer extends ConsumerWidget {
  const DiveCameraAppMediaPlayer({
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

    final videoMix = DivePreview(
      controller: state.videoMixes[0].controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          final state = elements.state;
          final source = state.videoSources[newIndex];
          final sceneItem = state.currentScene.findSceneItem(source);
          if (sceneItem != null) {
            sceneItem.setOrder(DiveSceneItemMovement.MOVE_TOP);
          }
          return true;
        });

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        videoMix,
      ],
    );

    return Container(color: Colors.black, child: mainContent);
  }
}
