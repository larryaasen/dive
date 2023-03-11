import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 2 - Image Viewer
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 2',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Image Viewer Example'),
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

  void _initialize(BuildContext context) {
    if (_initialized) return;

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveUI.setup(context);

    _elements = widget.elements;
    _diveCore = DiveCore();
    _diveCore.setupOBS(DiveCoreResolution.HD);

    final scene = DiveScene.create();
    _elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      _elements.updateState((state) => state..videoMixes.add(mix));
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize(context);
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
