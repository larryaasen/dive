import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_ui/dive_ui.dart';
// import 'package:dive_app/home_widget.dart';

class AppWidget extends StatefulWidget {
  @override
  _AppWidgetState createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final _audioSources = List<DiveAudioSource>();
  final _imageSources = List<DiveImageSource>();
  final _mediaSources = List<DiveMediaSource>();
  final _videoSources = List<DiveVideoSource>();
  final _videoMixes = List<DiveVideoMix>();
  final _streamingOutput = DiveOutput();
  DiveScene _currentScene;

  @override
  void initState() {
    super.initState();

    DivePlugin.platformVersion().then((value) => print("$value"));

    DiveScene.create('Scene 1').then((scene) => setup(scene));
  }

  void setup(DiveScene scene) {
    _currentScene = scene;

    // Print all input types to the log
    DiveInputTypes.all().then((inputTypes) {
      inputTypes.forEach((type) {
        print(type);
      });
    });

    DiveVideoMix.create().then((mix) {
      setState(() {
        _videoMixes.add(mix);
      });
    });

    DiveInputs.audio().then((audioInputs) {
      audioInputs.forEach((audioInput) {
        print(audioInput);
      });
    });

    DiveAudioSource.create('my audio').then((source) {
      setState(() {
        _audioSources.add(source);
      });
      _currentScene.addSource(source).then((item) {});
    });

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
          // source.play();
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
              IconButton(
                icon: const Icon(Icons.play_circle_fill_outlined),
                tooltip: 'Play video',
                onPressed: () {
                  _mediaSources[0].play().then((value) {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.live_tv),
                tooltip: 'Start streaming',
                onPressed: () {
                  if (_streamingOutput.streamingState ==
                      DiveOutputStreamingState.streaming) {
                    _streamingOutput.stop().then((value) {
                      setState(() {});
                    });
                  } else {
                    _streamingOutput.start().then((value) {
                      setState(() {});
                    });
                  }
                },
              ),
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
