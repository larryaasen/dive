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
  final _mediaSources = List<DiveMediaSource>();
  final _videoSources = List<DiveVideoSource>();
  final _videoMixes = List<DiveVideoMix>();

  @override
  void initState() {
    super.initState();

    DivePlugin.platformVersion().then((value) => print("$value"));

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

    DiveInputs.video().then((videoInputs) {
      videoInputs.forEach((videoInput) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          setState(() {
            _videoSources.add(source);
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
        source.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final box1 = DivePreview(
        _videoSources.length > 0 ? _videoSources[0].controller : null);
    final box2 = DivePreview(
        _mediaSources.length > 0 ? _mediaSources[0].controller : null);
    final box3 = DivePreview(
        _videoSources.length > 1 ? _videoSources[1].controller : null);
    final box4 = DivePreview(
        _videoSources.length > 1 ? _videoSources[1].controller : null);

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
      home: content,
    );
  }
}
