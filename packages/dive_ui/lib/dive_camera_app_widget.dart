import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// The Dive Camera App widget, that displays a list of live cameras.
class DiveCameraAppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  DiveCameraAppWidget({Key? key}) : super(key: key);

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
  DiveCameraAppBody({Key? key, this.elements}) : super(key: key);

  final DiveCoreElements? elements;

  @override
  _DiveCameraAppBodyState createState() => _DiveCameraAppBodyState();
}

class _DiveCameraAppBodyState extends State<DiveCameraAppBody> {
  late DiveCore _diveCore;
  DiveCoreElements? _elements;
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

    // Create the main scene.
    _elements!.addScene(DiveScene.create());

    DiveVideoMix.create().then((mix) {
      if (mix != null) {
        _elements!..addMix(mix);
      }
    });

    DiveInputs.video().forEach((videoInput) {
      print(videoInput);
      DiveVideoSource.create(videoInput).then((source) {
        if (source != null) {
          _elements!.addVideoSource(source);
          _elements!.state.currentScene?.addSource(source);
        }
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
    Key? key,
    required this.elements,
    required this.context,
  }) : super(key: key);

  final DiveCoreElements? elements;
  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elements!.provider);
    if (state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final videoMix = DivePreview(
      controller: state.videoMixes.first.controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          final state = elements!.state;
          final source = state.videoSources.toList()[newIndex];
          final sceneItem = state.currentScene?.findSceneItem(source);
          if (sceneItem != null) {
            sceneItem.setOrder(DiveSceneItemMovement.moveTop);
          }
          return true;
        });

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        Expanded(child: videoMix),
      ],
    );

    return Container(color: Colors.black, child: mainContent);
  }
}
