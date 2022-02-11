import 'package:dive/dive.dart';
import 'package:dive_video_source/dive_video_source.dart';
import 'package:flutter/material.dart';

void main() {
  runDiveApp();
  DiveLog.message('Dive Example - Images');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dive Example - Images',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Dive Example - Images'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DiveFrame? _imageFrame;
  DiveFrame? _mixFrame;
  DiveFrame? _videoFrame;
  DiveCompositingEngine? _compositingEngine;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    // Log the Dive input types: audio, text, video, etc.
    for (final type in DiveInputTypes.all) {
      DiveLog.message('$type');
    }

    /// Register the Dive video input provider for use in this app.
    DiveInputProviders.registerProvider(DiveVideoInputProvider());

    // Log the Dive input providers.
    for (final provider in DiveInputProviders.all) {
      DiveLog.message('$provider');
    }

    // Log the Dive inputs: Facetime Camera, Main Microphone, etc.
    for (final provider in DiveInputProviders.all) {
      provider.inputs().then((inputs) {
        inputs?.forEach((input) => DiveLog.message(input.name));
      });
    }

    final videoProvider = DiveVideoInputProvider();
    final videoSource = videoProvider.create(
        'video1',
        DiveCoreProperties.fromMap(
            {DiveVideoInputProvider.PROPERTY_INPUT_ID: '0x8020000005ac8514'}));

    onFrame(DiveDataStreamItem item) {
      if (item.frame is DiveFrame) {
        setState(() {
          _videoFrame = item.frame;
        });
      }
    }

    if (videoSource != null) {
      videoSource.setup().then((bool? result) {
        if (result != null && result) {
          videoSource.frameOutput.listen(onFrame);
        }
      });
    }

    final imageProvider = DiveImageInputProvider();
    final imageSource1 = imageProvider.create(
        "image1",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image1.jpg'
        }));

    final imageSource2 = imageProvider.create(
        "image2",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image2.jpg'
        }));

    if (imageSource1 != null && imageSource2 != null) {
      onDataImage(DiveDataStreamItem item) {
        if (item.frame is DiveFrame) {
          setState(() {
            _imageFrame = item.frame;
          });
        }
      }

      imageSource1.frameOutput.listen(onDataImage);

      const int timerResolution = 1000;
      final textSource = DiveTextClockSource.create(
          name: 'clock1',
          properties: DiveCoreProperties.fromMap(
              {DiveTextClockSource.propertyTimerResolution: timerResolution}));

      _compositingEngine = DiveCompositingEngine(
          name: 'composite1',
          frameInput1: imageSource1.frameOutput,
          frameInput2: imageSource2.frameOutput,
          textInput1: textSource.frameOutput);

      onData(DiveDataStreamItem item) {
        if (item.frame is DiveFrame) {
          setState(() {
            _mixFrame = item.frame;
          });
        }
      }

      _compositingEngine!.frameOutput.listen(onData);
      _compositingEngine!.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    // DiveLog.message("$_mixFrame");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Expanded(child: Image.asset('assets/image1.jpg')),
            if (_imageFrame != null)
              Expanded(child: Image(image: _imageFrame!.memoryImage)),
            if (_mixFrame != null && _mixFrame!.uiImage != null)
              RawImage(image: _mixFrame!.uiImage!),
            if (_videoFrame != null)
              Expanded(child: RawImage(image: _videoFrame!.uiImage)),
            // When creating the Image widget, use gaplessPlayback to avoid the
            // flickering.
            // if (_mixFrame != null)
            //   Image(image: _mixFrame!.memoryImage, gaplessPlayback: true),
          ],
        ),
      ),
    );
  }
}
