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
  BodyWidget({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  final _diveCore = DiveCore();
  bool _initialized = false;

  void _initialize() {
    if (_initialized) return;

    _diveCore.setupOBS(DiveCoreResolution.HD);

    final scene = DiveScene.create();
    widget.elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      if (mix != null) widget.elements.updateState((state) => state..videoMixes.add(mix));
    });

    DiveInputs.video().forEach((videoInput) {
      if (videoInput.name != null && videoInput.name!.contains('C920')) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          if (source != null) {
            widget.elements.updateState((state) => state..videoSources.add(source));
            widget.elements.updateState((state) => state..currentScene?.addSource(source));
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
          controller: state.videoMixes[0].controller,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final item = state.currentScene == null || state.currentScene!.sceneItems.isEmpty
        ? null
        : state.currentScene!.sceneItems[0];

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
