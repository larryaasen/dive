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
  BodyWidget({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  DiveCore _diveCore = DiveCore();
  bool _initialized = false;

  void _initialize() async {
    if (_initialized) return;

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    widget.elements.addScene(DiveScene.create());

    DiveVideoMix.create().then((mix) {
      if (mix != null) {
        widget.elements.addMix(mix);
      }
    });

    DiveInputs.video().forEach((videoInput) {
      if (videoInput.name != null && videoInput.name!.contains('C920')) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          if (source != null) {
            widget.elements.addVideoSource(source);
            widget.elements.state.currentScene!.addSource(source);
          }
        });
      }
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    return MediaPlayer(context: context, elements: widget.elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({super.key, required this.elements, required this.context});

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
          controller: state.videoMixes.first.controller,
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

class MyIconSet extends DiveIconSet {
  @override
  IconData get settingsButton => Icons.grid_on;
}
