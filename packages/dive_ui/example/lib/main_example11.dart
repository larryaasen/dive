import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

bool multiCamera = false;

/// Dive Example 11 - Configure Stream
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 11',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Configure Stream Example'),
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
    super.initState();
    _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diveCore.setupOBS(DiveCoreResolution.FULL_HD);

    final scene = DiveScene.create();
    widget.elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      if (mix != null) widget.elements.updateState((state) => state..videoMixes.add(mix));
    });

    DiveAudioSource.create('main audio').then((source) {
      if (source != null) {
        setState(() {
          widget.elements.updateState((state) => state..audioSources.add(source));
        });
        widget.elements.updateState((state) => state..currentScene?.addSource(source));

        DiveAudioMeterSource.create(source: source).then((volumeMeter) {
          setState(() {
            source.volumeMeter = volumeMeter;
          });
        });
      }
    });

    DiveInputs.video().forEach((videoInput) {
      print(videoInput);
      DiveVideoSource.create(videoInput).then((source) {
        if (source != null) {
          widget.elements.updateState((state) {
            state.videoSources.add(source);
            state.currentScene?.addSource(source);
            return state;
          });
        }
      });
    });

    // Create the streaming output
    final output = DiveOutput();
    widget.elements.updateState((state) => state.copyWith(streamingOutput: output));
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

    final volumeMeterSource = state.audioSources.firstWhere((source) => source.volumeMeter != null);
    final volumeMeter = volumeMeterSource.volumeMeter;
    if (volumeMeter == null) return SizedBox.shrink();

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DiveMeterPreview(
          controller: state.videoMixes[0].controller,
          volumeMeter: volumeMeter,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          elements.updateState((state) {
            final source = state.videoSources[newIndex];
            final sceneItem = state.currentScene?.findSceneItem(source);
            if (sceneItem != null) {
              sceneItem.setOrder(DiveSceneItemMovement.moveTop);
            }
            return state;
          });
          return true;
        });

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        Expanded(child: videoMix),
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
