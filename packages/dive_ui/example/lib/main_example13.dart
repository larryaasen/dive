import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive/dive.dart';

/// Dive Example 13 - This example shows how to live stream with display capture, one camera overlay,
/// a mic input, and background music.
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 13',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Live Stream Example'),
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
  BodyWidget({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  DiveCore _diveCore;
  DiveCoreElements _elements;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    if (_initialized) return;
    _initialized = true;

    _elements = widget.elements;
    _diveCore = DiveCore();
    await _diveCore.setupOBS(DiveCoreResolution.FULL_HD);

    final scene = DiveScene.create();
    _elements.updateState((state) => state.copyWith(currentScene: scene));

    final settings = DiveSettings();
    settings.set('display', 0); // Display #1
    settings.set('show_cursor', true); // Show the cursor
    settings.set('crop_mode', 0); // Crop mode: none
    final displayCaptureSource = DiveSource.create(
      inputType: DiveInputType(id: 'display_capture', name: 'Display Capture'),
      name: 'display capture 1',
      settings: settings,
    );
    _elements.updateState((state) {
      state.sources.add(displayCaptureSource);
      state.currentScene.addSource(displayCaptureSource).then((item) {
        // Scale the dispaly down to 50% to make it fit.
        final info = DiveTransformInfo(scale: DiveVec2(0.5, 0.5));
        item.updateTransformInfo(info);
      });
      return state;
    });

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
      if (videoInput.name.contains('Built-in')) {
        DiveVideoSource.create(videoInput).then((source) {
          _elements.updateState((state) {
            state.videoSources.add(source);
            state.currentScene.addSource(source).then((item) {
              final info = DiveTransformInfo(
                pos: DiveVec2(1350, 760),
                bounds: DiveVec2(533, 300),
                boundsType: DiveBoundsType.scaleInner,
              );
              item.updateTransformInfo(info);
            });
            return state;
          });
        });
      }
    });

    final file =
        '/Users/larry/Downloads/Amped - AmpassBeats by Murray Frost and Elgato/2. Skyline - Amped - AmpassBeats by Murray Frost.mp3';
    final mediaSettings = DiveMediaSourceSettings(localFile: file, isLocalFile: true, looping: true);
    // Add the local MP3 media source.
    DiveMediaSource.create(
            name: 'Background Music (MP3)', settings: mediaSettings, requiresVideoMonitor: false)
        .then((source) {
      if (source != null) {
        source.monitoringType = DiveCoreMonitoringType.none;
        source.volume = DiveCoreLevel.dB(-30.0);
        _elements.updateState((state) => state
          ..mediaSources.add(source)
          ..currentScene.addSource(source));
        source.play();
      }
    });

    // Create the streaming output
    final output = DiveOutput();
    _elements.updateState((state) => state.copyWith(streamingOutput: output));
  }

  @override
  Widget build(BuildContext context) {
    return MediaPlayer(context: context, elements: _elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({Key key, @required this.elements, @required this.context}) : super(key: key);

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

    final videoMix = Container(
        color: Colors.black,
        padding: EdgeInsets.all(4),
        child: DiveMeterPreview(
          controller: state.videoMixes[0].controller,
          volumeMeter: volumeMeter,
          aspectRatio: DiveCoreAspectRatio.HD.ratio,
        ));

    final mainContent = Row(
      children: [
        Expanded(child: videoMix),
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
