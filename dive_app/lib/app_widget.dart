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
  void architecting() {
    // DiveInputTypes.all().then((inputTypes) {});
    final inputType =
        DiveInputType(id: 'av_capture_input', name: 'Video Capture Device');
    // final videoInputType = DiveInputType.videoCaptureDevice();

    DiveInputs.video().then((videoInputs) {});

    final settings = DiveSettings();

    DiveSource.create(inputType: inputType, name: '', settings: settings)
        .then((source) {});

    // DiveVideoInput.create(id: "mmhmmCameraDevice", name: "mmhmm Camera")
    //     .then((DiveVideoInput videoInput) {
    //   DiveVideoSource.create(videoInput).then((source) {});
    // });
  }

  final _videoSources = List<DiveVideoSource>();

  @override
  void initState() {
    super.initState();

    // Print all input types to the log
    DiveInputTypes.all().then((inputTypes) {
      inputTypes.forEach((type) {
        print(type);
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
  }

  @override
  Widget build(BuildContext context) {
    DivePlugin.platformVersion().then((value) => print("$value"));

    Widget content;
    if (_videoSources.length > 1) {
      final box1 = DivePreview(_videoSources[0].controller);
      final box2 = DivePreview(_videoSources[1].controller);
      final box3 = DivePreview(_videoSources[0].controller);
      final box4 = DivePreview(_videoSources[1].controller);

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
