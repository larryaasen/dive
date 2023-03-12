import 'dart:async';
import 'dart:math';

import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

bool multiCamera = false;

/// Dive Example 5 - Multi Camera Mix
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 5',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Multi Camera Mix Example'),
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

    // YouTube settings
    // Replace this YouTube key with your own. This one is no longer valid.
    // output.serviceKey = '26qe-9gxw-9veb-kf2m-dhv3';
    // output.serviceUrl = 'rtmp://a.rtmp.youtube.com/live2';

    // Twitch Settings
    // Replace this Twitch key with your own. This one is no longer valid.
    output.serviceKey = 'live_276488556_uIKncv1zAGQ3kz5aVzCvfshg8W4ENC';
    output.serviceUrl = 'rtmp://live-iad05.twitch.tv/app/${output.serviceKey}';

    widget.elements.updateState((state) => state.copyWith(streamingOutput: output));
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
              controller: state.videoMixes[0].controller,
              volumeMeter: volumeMeter,
              aspectRatio: DiveCoreAspectRatio.HD.ratio,
            )));

    final cameras = DiveCameraList(
        elements: elements,
        state: state,
        onTap: (int currentIndex, int newIndex) {
          final state = elements.state;
          final source = state.videoSources[newIndex];
          final sceneItem = state.currentScene?.findSceneItem(source);
          if (sceneItem != null) {
            sceneItem.setOrder(DiveSceneItemMovement.moveTop);
          }
          return true;
        });

    final mainContent = Row(
      children: [
        if (state.videoSources.length > 0) cameras,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
