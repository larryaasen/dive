import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 3 - Video Camera
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 3',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Video Camera Example'),
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

  void _initialize(BuildContext context) async {
    if (_initialized) return;

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveUI.setup(context);

    _elements = widget.elements;
    _diveCore = DiveCore();
    await _diveCore.setupOBS(DiveCoreResolution.HD);

    final scene = DiveScene.create();
    _elements.updateState((state) => state.copyWith(currentScene: scene));

    DiveVideoMix.create().then((mix) {
      _elements.updateState((state) => state..videoMixes.add(mix));
    });

    DiveAudioSource.create('main audio').then((source) {
      setState(() {
        _elements.updateState((state) => state..audioSources.add(source));
      });
      _elements.updateState((state) => state..currentScene.addSource(source));

      DiveAudioMeterSource()
        ..create(source: source).then((volumeMeter) {
          setState(() {
            source.volumeMeter = volumeMeter;
          });
        });
    });

    DiveInputs.video().forEach((videoInput) {
      print(videoInput);
      DiveVideoSource.create(videoInput).then((source) {
        _elements.updateState((state) => state..videoSources.add(source));
        _elements.updateState((state) => state..currentScene.addSource(source));
      });
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

    final volumeMeterSource = state.audioSources.firstWhere((source) => source.volumeMeter != null);
    final volumeMeter = volumeMeterSource != null ? volumeMeterSource.volumeMeter : null;

    final videoMix = DiveMeterPreview(
      controller: state.videoMixes[0].controller,
      volumeMeter: volumeMeter,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final cameras = DiveCameraList(elements: elements, state: state);

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
