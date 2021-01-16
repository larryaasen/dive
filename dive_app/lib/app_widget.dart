import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_ui/dive_ui.dart';
// import 'package:dive_app/home_widget.dart';

class AppWidget extends StatefulWidget {
  @override
  _AppWidgetState createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  DiveCore _diveCore;
  final List<DiveAudioSource> _audioSources = [];
  final List<DiveImageSource> _imageSources = [];
  final List<DiveMediaSource> _mediaSources = [];
  final List<DiveVideoSource> _videoSources = [];
  final List<DiveVideoMix> _videoMixes = [];
  final _streamingOutput = DiveOutput();
  DiveScene _currentScene;
  bool _initialized = false;
  bool _enableCameras = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _diveCore = DiveCore();
    _diveCore.setupOBS();

    if (!_initialized) {
      _initialized = true;

      // DiveCore and DiveApp must use the same [BuildContext], so it needs
      // to be passed to DiveCore at the start. The method [DiveUI.setup] must
      // be called after [_AppWidgetState.initState] completes.
      DiveUI.setup(this.context);

      DiveScene.create('Scene 1').then((scene) => setup(scene));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void setup(DiveScene scene) {
    _currentScene = scene;

    // // Print all input types to the log
    // DiveInputTypes.all().then((inputTypes) {
    //   inputTypes.forEach((type) {
    //     print(type);
    //   });
    // });

    // DiveVideoMix.create().then((mix) {
    //   setState(() {
    //     _videoMixes.add(mix);
    //   });
    // });

    // DiveInputs.audio().then((audioInputs) {
    //   audioInputs.forEach((audioInput) {
    //     print(audioInput);
    //   });
    // });

    // DiveAudioSource.create('my audio').then((source) {
    //   setState(() {
    //     _audioSources.add(source);
    //   });
    //   _currentScene.addSource(source).then((item) {});
    // });

    if (_enableCameras) {
      DiveInputs.video().then((videoInputs) {
        var xLoc = 50.0;
        videoInputs.forEach((videoInput) {
          print(videoInput);
          DiveVideoSource.create(videoInput).then((source) {
            setState(() {
              _videoSources.add(source);
            });
            _currentScene.addSource(source).then((item) {
              final info = DiveTransformInfo(
                  pos: DiveVec2(xLoc, 50),
                  bounds: DiveVec2(500, 280),
                  boundsType: DiveBoundsType.SCALE_INNER);
              item.updateTransformInfo(info);
              xLoc += 680.0;
            });
          });
        });
      });
    }

    final localFile = '/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.mp4';
    DiveMediaSource.create(localFile).then((source) {
      if (source != null) {
        setState(() {
          _mediaSources.add(source);
        });
        _currentScene.addSource(source).then((item) {
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
          _imageSources.add(source);
        });
        _currentScene.addSource(source).then((item) {
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
          _imageSources.add(source);
        });
        _currentScene.addSource(source).then((item) {
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
    return buildMaterial(context);
  }

  Widget buildMaterial(BuildContext context) {
    final camerasText = Padding(
        padding: EdgeInsets.only(left: 10, top: 10, right: 10),
        child: Text('Cameras',
            style: TextStyle(color: Colors.grey, fontSize: 24)));
    final card1 = Padding(
        padding: EdgeInsets.all(10),
        child: Card(
            elevation: 10,
            child: AspectRatio(
                aspectRatio: 1280 / 720,
                child: DivePreview(_videoSources.length > 0
                    ? _videoSources[0].controller
                    : null))));
    final card2 = Padding(
        padding: EdgeInsets.all(10),
        child: Card(
            elevation: 10,
            child: AspectRatio(
                aspectRatio: 1280 / 720,
                child: DivePreview(_videoSources.length > 1
                    ? _videoSources[1].controller
                    : null))));

    final sources =
        Container(color: Colors.white, child: Wrap(spacing: 10, runSpacing: 0,
            // mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[camerasText, card1, card2]));

    final videoMix = Padding(
        padding: EdgeInsets.only(right: 10),
        child: Card(
            elevation: 10,
            child: Container(
                color: Colors.black,
                child: AspectRatio(
                    aspectRatio: 1280 / 720,
                    child: DivePreview(_videoMixes.length > 0
                        ? _videoMixes[0].controller
                        : null)))));

    final mainContent = Row(
      children: [
        Expanded(flex: 4, child: sources),
        Expanded(flex: 6, child: videoMix)
      ],
    );

    final mainContainer = Container(
      decoration: new BoxDecoration(color: Colors.white),
      child: Align(alignment: Alignment.topCenter, child: mainContent),
    );

    final content = mainContainer;

    return MaterialApp(
        title: 'Dive App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive App'),
            actions: <Widget>[
              DiveMediaButtonBar(
                  mediaSource:
                      _mediaSources.length == 0 ? null : _mediaSources[0]),
              DiveStreamPlayButton(streamingOutput: _streamingOutput),
            ],
          ),
          body: content,
        ));
  }

  Widget buildStudio(BuildContext context) {
    Widget content;
    final box1 = DivePreview(
        _videoSources.length > 0 ? _videoSources[0].controller : null);
    final box2 = DivePreview(
        _mediaSources.length > 0 ? _mediaSources[0].controller : null);
    final box3 = DivePreview(
        _videoSources.length > 1 ? _videoSources[1].controller : null);
    final box4 = DivePreview(
        _imageSources.length > 0 ? _imageSources[0].controller : null);

    content = GridView.count(
      primary: false,
      padding: const EdgeInsets.all(0),
      crossAxisCount: 2,
      childAspectRatio: 1280 / 720,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: [box1, box2, box3, box4],
      shrinkWrap: true,
    );

    final videoMix = AspectRatio(
        aspectRatio: 1280 / 720,
        child: DivePreview(
            _videoMixes.length > 0 ? _videoMixes[0].controller : null));

    content = GridView.count(
      primary: false,
      padding: const EdgeInsets.all(1.0),
      crossAxisCount: 2,
      childAspectRatio: 1280 / 720,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: [
        content,
        videoMix,
        Container(decoration: new BoxDecoration(color: Colors.blue)),
        Container(decoration: new BoxDecoration(color: Colors.blue))
      ],
      shrinkWrap: true,
    );

    final mainContainer = Container(
      decoration: new BoxDecoration(color: Colors.black),
      child: content,
    );

    content = mainContainer;

    return MaterialApp(
        title: 'Dive App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: content);
  }
}
