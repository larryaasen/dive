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

    // final localFile = '/Users/larry/Downloads/Nicholas-Nationals-Play-Ball.mp4';
    // DiveMediaSource.create(localFile).then((source) {
    //   if (source != null) {
    //     setState(() {
    //       _mediaSources.add(source);
    //     });
    //     source.play();
    //   }
    // });

    DiveVideoMix.create().then((mix) {
      setState(() {
        _videoMixes.add(mix);
      });
    });

    DiveInputs.video().then((videoInputs) {
      videoInputs.forEach((videoInput) {
        print(videoInput);
        // if (videoInput.id == '0x8020000005ac8514') {
        DiveVideoSource.create(videoInput).then((source) {
          setState(() {
            _videoSources.add(source);
          });
        });
        // }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_videoSources.length > 0) {
      final box1 = DivePreview(_videoSources[0].controller);
      final box2 = DivePreview(_videoSources[0].controller);
      final box3 = DivePreview(_videoSources[1].controller);
      final box4 = DivePreview(_videoMixes[0].controller);

      content = Center(
          child: GridView.count(
        primary: false,
        padding: const EdgeInsets.all(1.5),
        crossAxisCount: 2,
        childAspectRatio: 1280 / 720,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        children: [box1, box2, box3, box4],
        shrinkWrap: true,
      ));
    } else {
      content = Container();
    }

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
