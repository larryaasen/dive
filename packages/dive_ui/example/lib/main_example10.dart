import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 10 - Icon Set
void main() {
  /// Setup a custom set of icons.
  DiveUI.iconSet = MyIconSet();

  runDiveUIApp(AppWidget());
  print("*********** ============ app ending");
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 10',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Icon Set Example'),
            actions: <Widget>[
              DiveSettingsButton(),
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
        _elements.updateState((state) => state..videoMixes.add(mix));
      });

      DiveInputs.video().forEach((videoInput) {
        if (videoInput.name.contains('C920')) {
          print(videoInput);
          DiveVideoSource.create(videoInput).then((source) {
            _elements.updateState((state) => state..videoSources.add(source));
            _elements.updateState((state) => state..currentScene.addSource(source));
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

    final mainContent = Row(
      children: [
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}

class MyIconSet extends DiveIconSet {
  @override
  IconData get settingsButton => Icons.grid_on;
}
