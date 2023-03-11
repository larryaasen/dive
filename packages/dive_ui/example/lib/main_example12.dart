import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 12 - Display capture
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Display Capture Example'),
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
    await _diveCore.setupOBS(DiveCoreResolution.FULL_HD);

    final scene = DiveScene.create();
    _elements.updateState((state) => state.copyWith(currentScene: scene));

    final settings = DiveSettings();
    settings.set('display', 0); // Display #0
    settings.set('show_cursor', true); // Show the cursor
    settings.set('crop_mode', 0); // Crop mode: none
    final displayCaptureSource = DiveSource.create(
      inputType: DiveInputType(id: 'display_capture', name: 'Display Capture'),
      name: 'display capture 1',
      settings: settings,
    );
    _elements.updateState((state) => state..sources.add(displayCaptureSource));
    _elements.updateState((state) => state..currentScene.addSource(displayCaptureSource));

    DiveVideoMix.create().then((mix) {
      _elements.updateState((state) => state..videoMixes.add(mix));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaPlayer(context: context, elements: _elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({Key key, @required this.elements, @required this.context}) : super(key: key);

  final DiveCoreElements elements;
  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elements.provider);
    if (state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DivePreview(
          controller: state.videoMixes[0].controller,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final mainContent = Row(
      children: [
        Expanded(child: videoMix),
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
