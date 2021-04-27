import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive_core/dive_core.dart';

void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // // Configure globally for all Equatable instances via EquatableConfig
  // EquatableConfig.stringify = true;

  runApp(ProviderScope(child: AppWidget()));
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive UI Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Media Player Example'),
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

  static const bool _enableOBS = true; // Set to false for debugging

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    _elements = widget.elements;
    _diveCore = DiveCore();
    if (_enableOBS) {
      _diveCore.setupOBS(DiveCoreResolution.HD);
      DiveScene.create('Scene 1').then((scene) => setup(scene));
    }

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveCore.providerContainer = ProviderScope.containerOf(context);

    _initialized = true;
  }

  void setup(DiveScene scene) {
    _elements.currentScene = scene;

    DiveVideoMix.create().then((mix) {
      setState(() {
        _elements.videoMixes.add(mix);
      });
    });

    DiveAudioSource.create('my audio').then((source) {
      setState(() {
        _elements.audioSources.add(source);
      });
      _elements.currentScene.addSource(source).then((item) {});
    });

    final localFile = '/Users/larry/Downloads/SampleVideo_1280x720_5mb.mp4';
    DiveMediaSource.create(localFile).then((source) {
      if (source != null) {
        DiveVolumeMeter()
          ..create(source: source).then((volumeMeter) {
            setState(() {
              source.volumeMeter = volumeMeter;
            });
          });

        setState(() {
          _elements.mediaSources.add(source);
        });
        _elements.currentScene.addSource(source);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_elements.mediaSources.length == 0 ||
        _elements.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final mediaButtons = Container(
        height: 40,
        color: Colors.black,
        child: SizedBox.expand(
            child: Container(
                alignment: Alignment.center,
                child: DiveMediaButtonBar(
                    iconColor: Colors.white54,
                    mediaSource: _elements.mediaSources[0]))));

    final videoMix = DiveMeterPreview(
      volumeMeter: _elements.mediaSources[0].volumeMeter,
      controller: _elements.videoMixes[0].controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final audio = Container(
        height: 40,
        color: Colors.black,
        padding: EdgeInsets.all(5),
        child: SizedBox.expand(
            child: DiveAudioMeter(
                volumeMeter: _elements.mediaSources[0].volumeMeter,
                vertical: false)));

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        videoMix,
        mediaButtons,
        audio,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
