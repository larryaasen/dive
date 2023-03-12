import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 14 - Multiple Scenes
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 14',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Multiple Scenes Example'),
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
  final _diveCore = DiveCore();
  bool _initialized = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () => _initialize());
    super.initState();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    widget.elements.addScene(DiveScene.create());

    // Create a second scene.
    final scene2 = widget.elements.addScene(DiveScene.create());

    DiveVideoMix.create().then((mix) {
      if (mix != null)
        widget.elements
            .updateState((state) => state.copyWith(videoMixes: state.videoMixes.toList()..add(mix)));
    });

    DiveInputs.video().forEach((videoInput) {
      if (videoInput.name != null && videoInput.name!.contains('FaceTime')) {
        // Create a video source.
        DiveVideoSource.create(videoInput).then((source) async {
          if (source != null) {
            // Save the video source.
            widget.elements.updateState(
                (state) => state.copyWith(videoSources: state.videoSources.toList()..add(source)));

            // Add the video source to scene 1 (the current scene).
            final scenItem = await widget.elements.state.currentScene?.addSource(source);
            if (scenItem != null) {
              // Update the position and scale of the video source.
              final info = await scenItem.getTransformInfo();
              final newInfo = info.copyWith(scale: DiveVec2(0.7, 0.7));
              scenItem.updateTransformInfo(newInfo);
            }

            // Add the video source to scene 2.
            final scenItem2 = await scene2.addSource(source);

            // Update the position and scale of the video source.
            final info = await scenItem2.getTransformInfo();
            final newInfo = info.copyWith(pos: DiveVec2(300, 300), scale: DiveVec2(0.3, 0.3));
            scenItem2.updateTransformInfo(newInfo);
          }
        });
      }
    });

    // Wait 7 seconds and then switch to scene 2.
    Future.delayed(Duration(seconds: 7), () {
      widget.elements.changeCurrentScene(scene2);
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
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
          controller: state.videoMixes[0].controller,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));
    return videoMix;
  }
}
