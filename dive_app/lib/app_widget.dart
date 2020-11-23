import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_core/preview_controller.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/dive_device.dart';
import 'package:dive_ui/dive_ui.dart';
// import 'package:dive_app/home_widget.dart';

class AppWidget extends StatelessWidget {
  // TODO: wish this controller was not exposed outside of TexturePreview().
  final TextureController controller = TextureController();

  @override
  Widget build(BuildContext context) {
    controller.initialize();

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

    return MaterialApp(
      title: 'Dive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Column(
        children: [
          Text('Dive App'),
          TexturePreview(controller),
        ],
      ),
    );
  }
}
