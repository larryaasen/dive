import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 1 - Media Player
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 1',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Media Player Example'),
            actions: <Widget>[
              DiveVideoPickerButton(elements: _elements),
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

  @override
  void initState() {
    Future.delayed(Duration.zero, () => _initialize());
    super.initState();
  }

  void _initialize() {
    _diveCore.setupOBS(DiveCoreResolution.HD);

    final scene = DiveScene.create();
    widget.elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      if (mix != null) {
        widget.elements.updateState((state) => state..videoMixes.add(mix));
      }
    });
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
    print("MediaPlayer.build started");
    final state = ref.watch(elements.provider);
    print("MediaPlayer.build state=$state");
    if (state.mediaSources.length == 0 || state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }
    print("MediaPlayer.build usable state");
    final source = state.mediaSources[0];
    final videoMix = state.videoMixes[0];

    final mediaButtons = Container(
        height: 40,
        color: Colors.black,
        child: SizedBox.expand(
            child: Container(
                alignment: Alignment.center,
                child: DiveMediaButtonBar(iconColor: Colors.white54, mediaSource: source))));

    final meterVideoMix = DivePreview(
      controller: videoMix.controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        meterVideoMix,
        mediaButtons,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
