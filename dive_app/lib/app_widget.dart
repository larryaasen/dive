import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_ui/dive_ui.dart';

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
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
              DiveStreamPlayButton(streamingOutput: _elements.streamingOutput),
              menuButton,
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
  final _referencePanels = DiveReferencePanelsCubit();
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

    // DiveCore and DiveApp must use the same [BuildContext], so it needs
    // to be passed to DiveCore at the start. The method [DiveUI.setup] must
    // be called after [initState] completes.
    DiveUI.setup(this.context);

    _initialized = true;
  }

  void setup(DiveScene scene) {
    _elements.currentScene = scene;

    // Print all input types to the log
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

    DiveInputs.audio().then((audioInputs) {
      audioInputs.forEach((audioInput) {
        print(audioInput);
      });
    });

    DiveAudioSource.create('my audio').then((source) {
      setState(() {
        _elements.audioSources.add(source);
      });
      _elements.currentScene.addSource(source).then((item) {});
    });

    var panelIndex = 0;

    if (_enableCameras) {
      DiveInputs.video().then((videoInputs) {
        var xLoc = 50.0;
        videoInputs.forEach((videoInput) {
          print(videoInput);
          DiveVideoSource.create(videoInput).then((source) {
            setState(() {
              _elements.videoSources.add(source);

              // Auto assign the video source to a panel
              _referencePanels.assignSource(
                  source, _referencePanels.state.panels[panelIndex]);
              panelIndex++;
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
      });
    }

    final localFile = '/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.mp4';
    DiveMediaSource.create(localFile).then((source) {
      if (source != null) {
        setState(() {
          _elements.mediaSources.add(source);

          // Auto assign the video source to a panel
          _referencePanels.assignSource(
              source, _referencePanels.state.panels[panelIndex]);
          panelIndex++;
        });
        _elements.currentScene.addSource(source).then((item) {
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
          _elements.imageSources.add(source);
        });
        _elements.currentScene.addSource(source).then((item) {
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
          _elements.imageSources.add(source);
        });
        _elements.currentScene.addSource(source).then((item) {
          // final info = DiveTransformInfo(
          //     pos: DiveVec2(590, 298),
          //     bounds: DiveVec2(100, 124),
          //     boundsType: DiveBoundsType.SCALE_INNER);
          // item.updateTransformInfo(info);
        });
      }
    });
  }

  Widget _widgetForSource(
    DiveSource source,
    DiveReferencePanelsCubit referencePanels,
    DiveReferencePanel panel,
  ) {
    final type = source == null ? DiveSource : source.runtimeType;
    Widget widget;
    switch (type) {
      case DiveMediaSource:
        widget = DiveSourceCard(
          child: MediaPreview(source as DiveMediaSource),
          elements: _elements,
          referencePanels: referencePanels,
          panel: panel,
        );
        break;
      case DiveVideoSource:
        widget = DiveSourceCard(
          child: DivePreview((source as DiveVideoSource).controller),
          elements: _elements,
          referencePanels: referencePanels,
          panel: panel,
        );
        break;
      case DiveSource:
        widget = DiveSourceCard(
          child: Container(color: Theme.of(context).primaryColor),
          elements: _elements,
          referencePanels: referencePanels,
          panel: panel,
        );
        break;
      default:
        widget = Container();
        break;
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider<DiveReferencePanelsCubit>(
        create: (context) => _referencePanels,
      ),
    ], child: buildApp(context));
  }

  Widget buildApp(BuildContext context) {
    return BlocBuilder<DiveReferencePanelsCubit, DiveReferencePanels>(
        builder: (context, referencePanels) {
      // Build the card list from the assigned panels
      final cardList = referencePanels.panels
          .map((panel) => _widgetForSource(panel.assignedSource,
              BlocProvider.of<DiveReferencePanelsCubit>(context), panel))
          .toList();

      final aspectRatio = DiveCoreAspectRatio.HD.ratio;
      final sourceGrid = DiveGrid(aspectRatio: aspectRatio, children: cardList);

      final sources = Container(
          child:
              Wrap(spacing: 10, runSpacing: 0, children: <Widget>[sourceGrid]));

      final videoMix = Padding(
          padding: EdgeInsets.only(left: 1, right: 0),
          child: IntrinsicHeight(
              child: DivePreview(
                  _elements.videoMixes.length > 0
                      ? _elements.videoMixes[0].controller
                      : null,
                  aspectRatio: DiveCoreAspectRatio.HD.ratio)));

      final mainContent = Padding(
          padding: EdgeInsets.only(left: 20, top: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: sources),
              Expanded(flex: 4, child: videoMix)
            ],
          ));

      final body = Container(
          color: Theme.of(context).scaffoldBackgroundColor, child: mainContent);
      return body;
    });
  }

/*
  Widget buildStudio(BuildContext context) {
    Widget content;
    final box1 = DivePreview(_elements.videoSources.length > 0
        ? _elements.videoSources[0].controller
        : null);
    final box2 = DivePreview(_elements.mediaSources.length > 0
        ? _elements.mediaSources[0].controller
        : null);
    final box3 = DivePreview(_elements.videoSources.length > 1
        ? _elements.videoSources[1].controller
        : null);
    final box4 = DivePreview(_elements.imageSources.length > 0
        ? _elements.imageSources[0].controller
        : null);

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

    final videoMix = DivePreview(_elements.videoMixes.length > 0
        ? _elements.videoMixes[0].controller
        : null);

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
  */
}
