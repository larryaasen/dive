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
  bool _enableOBS = true;
  bool _enableCameras = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _diveCore = DiveCore();
    if (_enableOBS) _diveCore.setupOBS(DiveCoreResolution.HD);

    if (!_initialized) {
      _initialized = true;

      // DiveCore and DiveApp must use the same [BuildContext], so it needs
      // to be passed to DiveCore at the start. The method [DiveUI.setup] must
      // be called after [_AppWidgetState.initState] completes.
      DiveUI.setup(this.context);

      DiveScene.create('Scene 1').then((scene) => setup(scene));
    }
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
          // final info = DiveTransformInfo(
          //     pos: DiveVec2(50, 330),
          //     bounds: DiveVec2(500, 280),
          //     boundsType: DiveBoundsType.SCALE_INNER);
          // item.updateTransformInfo(info);
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
          // final info = DiveTransformInfo(
          //     pos: DiveVec2(730, 330),
          //     bounds: DiveVec2(500, 280),
          //     boundsType: DiveBoundsType.SCALE_INNER);
          // item.updateTransformInfo(info);
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
          // final info = DiveTransformInfo(
          //     pos: DiveVec2(590, 298),
          //     bounds: DiveVec2(100, 124),
          //     boundsType: DiveBoundsType.SCALE_INNER);
          // item.updateTransformInfo(info);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildMaterial(context);
  }

  Widget buildMaterial(BuildContext context) {
    final card1 = IntrinsicHeight(
        child: DiveSourceCard(
            child: DivePreview(
                _videoSources.length > 0 ? _videoSources[0].controller : null,
                aspectRatio: DiveCoreAspectRatio.HD.ratio)));
    final card2 = DiveSourceCard(
        child: DivePreview(
            _videoSources.length > 1 ? _videoSources[1].controller : null,
            aspectRatio: DiveCoreAspectRatio.HD.ratio));
    final card3 = DiveSourceCard(
        child: DivePreview(
            _videoSources.length > 2 ? _videoSources[2].controller : null,
            aspectRatio: DiveCoreAspectRatio.HD.ratio));
    final card4 = DiveSourceCard(
        child:
            MediaPreview(_mediaSources.length > 0 ? _mediaSources[0] : null));
    final card5 = DiveSourceCard(child: null);
    final card6 = DiveSourceCard(child: null);
    final cardList = [card1, card2, card3, card4, card5, card6];

    final aspectRatio = DiveCoreAspectRatio.HD.ratio;

    // final widgets = List.generate(
    //     14,
    //     (i) => Container(
    //           color: Colors.green,
    //           padding: EdgeInsets.all(2),
    //           child: Align(
    //               alignment: Alignment.center,
    //               child: Card(
    //                   child: DivePreview(
    //                       _videoSources.length > 0
    //                           ? _videoSources[0].controller
    //                           : null,
    //                       aspectRatio: DiveCoreAspectRatio.HD.ratio))),
    //         ));
    final sourceGrid = DiveGrid(aspectRatio: aspectRatio, children: cardList);

    // final sourceRow = Row(
    //   children: [card1, card2, card3, card4],
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   crossAxisAlignment: CrossAxisAlignment.center,
    // );

    // final camerasText = Padding(
    //     padding: EdgeInsets.only(left: 10, top: 10, right: 10),
    //     child: Text('Cameras',
    //         style: TextStyle(color: Colors.grey, fontSize: 24)));

    final sources = Container(
        // padding: EdgeInsets.only(bottom: 10, right: 10),
        color: Colors.white,
        child: Wrap(spacing: 10, runSpacing: 0,
            // mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[sourceGrid]));

    final videoMix = IntrinsicHeight(
        child: DiveSourceCard(
            child: Container(
                color: Colors.black,
                child: DivePreview(
                    _videoMixes.length > 0 ? _videoMixes[0].controller : null,
                    aspectRatio: DiveCoreAspectRatio.HD.ratio))));

    final mainContent = Padding(
        padding: EdgeInsets.only(left: 20, top: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: sources),
            Expanded(flex: 4, child: videoMix)
          ],
        ));

    // final mainLayout = Expanded(
    //     child: Column(children: [
    //   Row(children: [Expanded(child: Container(color: Colors.blueAccent))]),
    //   Row(children: [Expanded(child: Container(color: Colors.orangeAccent))]),
    // ]));

    final body = Container(color: Colors.limeAccent, child: mainContent);

    final menuButton = IconButton(icon: Icon(Icons.menu), onPressed: () {});

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
              DiveStreamPlayButton(streamingOutput: _streamingOutput),
              menuButton,
            ],
          ),
          body: body,
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
      childAspectRatio: DiveCoreAspectRatio.HD.toDouble,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: [box1, box2, box3, box4],
      shrinkWrap: true,
    );

    final videoMix =
        DivePreview(_videoMixes.length > 0 ? _videoMixes[0].controller : null);

    content = GridView.count(
      primary: false,
      padding: const EdgeInsets.all(1.0),
      crossAxisCount: 2,
      childAspectRatio: DiveCoreAspectRatio.HD.toDouble,
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
