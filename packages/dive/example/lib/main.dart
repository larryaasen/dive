import 'package:dive/dive.dart';
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
  DiveCompositingEngine? _compositingEngine;

  @override
  void initState() {
    initialize();
  }

  void initialize() {
    final imageProvider = DiveImageInputProvider();
    final imageSource1 = imageProvider.create(
        "image1",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image1.jpg'
        }));

    final imageSource2 = imageProvider.create(
        "image2",
        DiveCoreProperties.fromMap({
          DiveImageInputProvider.PROPERTY_RESOURCE_NAME: 'assets/image1.jpg'
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

      _compositingEngine = DiveCompositingEngine(
          name: 'composite1',
          frameInput1: imageSource1.frameOutput,
          frameInput2: imageSource2.frameOutput);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: Image.asset('assets/image1.jpg')),
            if (_imageFrame != null)
              Expanded(child: Image(image: _imageFrame!.memoryImage)),
            if (_mixFrame != null)
              Expanded(child: Image(image: _mixFrame!.memoryImage)),
          ],
        ),
      ),
    );
  }
}
