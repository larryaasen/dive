import 'package:flutter/material.dart';
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
        title: 'Dive Core App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Core App'),
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

  static const bool _enableOBS = true;
  static const bool _enableCameras = _enableOBS && true;

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

    DiveInputTypes.all().then((inputTypes) {
      inputTypes.forEach((type) {
        print(type);
      });
    });

    DiveVideoMix.create().then((mix) {
      setState(() {
        _elements.videoMixes.add(mix);
      });
    });

    DiveInputs.audio().forEach((audioInput) {
      print(audioInput);
    });

    DiveAudioSource.create('my audio').then((source) {
      setState(() {
        _elements.audioSources.add(source);
      });
      _elements.currentScene.addSource(source).then((item) {});
    });

    if (_enableCameras) {
      var xLoc = 50.0;
      DiveInputs.video().forEach((videoInput) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          setState(() {
            _elements.videoSources.add(source);
          });
          _elements.currentScene.addSource(source).then((item) {
            final info = DiveTransformInfo(
                pos: DiveVec2(xLoc, 50),
                bounds: DiveVec2(500, 280),
                boundsType: DiveBoundsType.SCALE_INNER);
            item.updateTransformInfo(info);
            xLoc += 680.0;
          });
        });
      });
    }

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
        _elements.currentScene.addSource(source).then((item) {
          final info = DiveTransformInfo(
              pos: DiveVec2(50, 330),
              bounds: DiveVec2(500, 280),
              boundsType: DiveBoundsType.SCALE_INNER);
          item.updateTransformInfo(info);
        });
      }
    });

    final file1 = '/Users/larry/Downloads/MacBookPro13.jpg';
    DiveImageSource.create(file1).then((source) {
      if (source != null) {
        setState(() {
          _elements.imageSources.add(source);
        });
        _elements.currentScene.addSource(source).then((item) {
          final info = DiveTransformInfo(
              pos: DiveVec2(730, 330),
              bounds: DiveVec2(500, 280),
              boundsType: DiveBoundsType.SCALE_INNER);
          item.updateTransformInfo(info);
        });
      }
    });

    final file2 = '/Users/larry/Downloads/logo_flutter_1080px_clr.png';
    DiveImageSource.create(file2).then((source) {
      if (source != null) {
        setState(() {
          _elements.imageSources.add(source);
        });
        _elements.currentScene.addSource(source).then((item) {
          final info = DiveTransformInfo(
              pos: DiveVec2(590, 298),
              bounds: DiveVec2(100, 124),
              boundsType: DiveBoundsType.SCALE_INNER);
          item.updateTransformInfo(info);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('dive_core'),
    );
  }
}
