import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 8 - Positioning
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 8',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Positioning Example'),
            actions: <Widget>[
              DiveImagePickerButton(elements: _elements),
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

  void _initialize() {
    if (_initialized) return;

    _elements = widget.elements;
    _diveCore = DiveCore();
    _diveCore.setupOBS(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.copyWith(currentScene: scene));

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state.videoMixes.add(mix));
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

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DiveMeterPreview(
          controller: state.videoMixes[0].controller,
          meterVertical: true,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final item = state.currentScene.sceneItems.isEmpty ? null : state.currentScene.sceneItems[0];

    final camera = Container(
        height: 200,
        width: 200 * DiveCoreAspectRatio.HD.ratio,
        child: DiveSourceCard(
          item: item,
          child: DivePreview(
              controller: state.videoSources.length == 0 ? null : (state.videoSources[0]).controller,
              aspectRatio: DiveCoreAspectRatio.HD.ratio),
          elements: elements,
        ));

    final mainContent = Row(
      children: [
        camera,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
