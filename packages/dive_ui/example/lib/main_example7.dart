import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 7 - Audio Inputs
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 7',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Audio Inputs Example'),
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

    DiveVideoMix.create().then((mix) {
      if (mix != null) widget.elements.addMix(mix);
    });

    DiveInputs.audio().forEach((audioInput) {
      // Create an audio source.
      DiveAudioSource.create("audio", input: audioInput).then((source) {
        if (source != null) {
          widget.elements.state.currentScene?.addSource(source);
          DiveAudioMeterSource.create(source: source).then((volumeMeter) {
            source.volumeMeter = volumeMeter;
          });
          widget.elements.addAudioSource(source);
        }
      });
    });

    DiveInputs.video().forEach((videoInput) {
      if (videoInput.name != null && videoInput.name!.contains('C920')) {
        DiveVideoSource.create(videoInput).then((source) {
          if (source != null) {
            widget.elements.addVideoSource(source);
            widget.elements.state.currentScene?.addSource(source);
          }
        });
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
    final state = ref.watch(elements.provider);
    if (state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final volumeMeterSource = state.audioSources.firstWhere((source) => source.volumeMeter != null);
    final volumeMeter = volumeMeterSource.volumeMeter;
    if (volumeMeter == null) return SizedBox.shrink();

    final videoMix = DiveMeterPreview(
      controller: state.videoMixes.first.controller,
      volumeMeter: volumeMeter,
      meterVertical: true,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final audios = DiveAudioList(elements: elements, state: state);

    final mainContent = Row(
      children: [
        if (state.audioSources.length > 0) audios,
        Expanded(child: videoMix),
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
