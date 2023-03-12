import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 2 - Image Viewer
void main() {
  final _elements = DiveCoreElements();

  runDiveUIApp(SampleAppWidget(
    title: 'Dive Example 2',
    barTitle: 'Dive Image Viewer Example',
    elements: _elements,
    body: BodyWidget(elements: _elements),
    actions: <Widget>[
      DiveImagePickerButton(elements: _elements),
    ],
  ));
}

class SampleAppWidget extends StatelessWidget {
  SampleAppWidget({
    super.key,
    required this.title,
    required this.barTitle,
    required this.elements,
    required this.body,
    this.actions,
  });

  final String title;
  final String barTitle;
  final DiveCoreElements elements;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text(barTitle),
            actions: actions,
          ),
          body: body,
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

  void _initialize(BuildContext context) {
    if (_initialized) return;

    // /// DiveCore and other modules must use the same [ProviderContainer], so
    // /// it needs to be passed to DiveCore at the start.
    // DiveUI.setup(context);

    _diveCore.setupOBS(DiveCoreResolution.HD);

    final scene = DiveScene.create();
    widget.elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      if (mix != null) widget.elements.updateState((state) => state..videoMixes.add(mix));
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize(context);
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

    final videoMix =
        DivePreview(controller: state.videoMixes[0].controller, aspectRatio: DiveCoreAspectRatio.HD.ratio);

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
