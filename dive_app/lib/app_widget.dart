import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_core/preview_controller.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/dive_device.dart';
import 'package:dive_ui/dive_ui.dart';
// import 'package:dive_app/home_widget.dart';

class AppWidget extends StatefulWidget {
  // TODO: wish this controller was not exposed outside of TexturePreview().

  @override
  _AppWidgetState createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  TextureController controller1 = TextureController(
      name: "FaceTime HD Camera (Built-in)", sourceId: "0x8020000005ac8514");
  TextureController controller2 = TextureController(
      name: "FaceTime HD Camera (Built-in)", sourceId: "0x8020000005ac8514");

  @override
  void initState() {
    super.initState();
    controller1.initialize().then((value) {
      setState(() {});
    });
    controller2.initialize().then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    DivePlugin.platformVersion().then((value) => print("$value"));
    DivePlugin.devicesDescription().then((value) => print("$value"));
    DivePlugin.devices().then((List<DiveDevice> devices) {
      if (devices == null) {
        return;
      }
      devices.forEach((device) {
        print("device: $device");
        if (device.mediaType == "video") {}
      });
    });

    final producer = ImageFrameProducer();
    producer.loadImage().then((value) => print(value));

    final rowCount = 4;
    final colCount = 4;

    final box1 = TexturePreview(controller2);
    final box2 = TexturePreview(controller2);
    final box3 = TexturePreview(controller2);
    final box4 = TexturePreview(controller2);

    final content = Center(
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
