import 'dart:async';
import 'dart:math';

import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

bool multiCamera = false;

/// Dive Example 15 - Multi Camera Streaming and Recording
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 15',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Multi Camera Streaming and Recording Example'),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.all_inbox_rounded), onPressed: () => _switchToMultiCamera()),
              DiveOutputButton(elements: _elements),
            ],
          ),
          body: BodyWidget(elements: _elements),
        ));
  }

  void _switchToMultiCamera() {
    final points = [Point<double>(680, 100), Point<double>(200, 370), Point<double>(0, 0)];
    multiCamera = true;
    _elements.updateState((state) {
      state.currentScene?.removeAllSceneItems();

      var index = 0;
      state.videoSources.forEach((videoSource) {
        state.currentScene?.addSource(videoSource).then((item) {
          final point = points[index];
          index++;
          final info = DiveTransformInfo(
            pos: DiveVec2(point.x, point.y),
            bounds: DiveVec2(350 * DiveCoreAspectRatio.HD.ratio, 0),
            boundsType: DiveBoundsType.scaleInner,
          );
          item.updateTransformInfo(info);
        });
      });
      return state;
    });

    // Set animation timer
    final ticks = 10;
    int tickCount = 0;
    Timer.periodic(Duration(milliseconds: 80), (timer) {
      final state = _elements.state;
      state.currentScene?.sceneItems.forEach((item) {
        final height = 350.0;
        final x = (height * DiveCoreAspectRatio.HD.ratio) * (tickCount / ticks);
        final y = height * (tickCount / ticks);
        final info = DiveTransformInfo(bounds: DiveVec2(x, y));
        item.updateTransformInfo(info);
      });
      tickCount++;
      if (tickCount == ticks) {
        timer.cancel();
      }
    });
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

    await _diveCore.setupOBS(DiveCoreResolution.HD);

    // Create the main scene.
    widget.elements.addScene(DiveScene.create());

    DiveVideoMix.create().then((mix) {
      if (mix != null) widget.elements.addMix(mix);
    });

    DiveAudioSource.create('main audio').then((source) {
      if (source != null) {
        widget.elements.addAudioSource(source);
        widget.elements.state.currentScene?.addSource(source);

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
          widget.elements.addVideoSource(source);
          widget.elements.state.currentScene?.addSource(source);
        }
      });
    });

    // Create the streaming output
    final streamingOutput = DiveStreamingOutput();

    // YouTube settings
    // Replace this YouTube key with your own. This one is no longer valid.
    // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
    // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

    // Twitch Settings
    // Replace this Twitch key with your own. This one is no longer valid.
    streamingOutput.serviceKey = '-----';
    streamingOutput.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${streamingOutput.serviceKey}';

    widget.elements.addStreamingOutput(streamingOutput);

    // Create the recording output
    final recordingOutput = DiveRecordingOutput();
    widget.elements.addRecordingOutput(recordingOutput);

    // Start recording.
    recordingOutput.start('/Users/larry/Movies/dive/dive1.mkv');
  }

  @override
  Widget build(BuildContext context) {
    return MediaPlayer(context: context, elements: widget.elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({
    super.key,
    required this.elements,
    required this.context,
  });

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

    final videoMix = Flexible(
        child: Container(
            color: Colors.black,
            padding: EdgeInsets.all(4),
            child: DiveMeterPreview(
              controller: state.videoMixes.first.controller,
              volumeMeter: volumeMeter,
              aspectRatio: DiveCoreAspectRatio.HD.ratio,
            )));

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          final state = elements.state;
          final source = state.videoSources.toList()[newIndex];
          final sceneItem = state.currentScene?.findSceneItem(source);
          if (sceneItem != null) {
            sceneItem.setOrder(DiveSceneItemMovement.moveTop);
          }
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
