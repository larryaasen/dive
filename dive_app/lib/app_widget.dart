import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';
// import 'package:dive_app/home_widget.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DiveCore.platformVersion.then((value) => print("$value"));
    // DiveCore.devicesDescription.then((value) => print("$value"));
    DiveCore.devices.then((List<DiveDevice> devices) {
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
      home: Text('Dive App'),
    );
  }
}
