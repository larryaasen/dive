import 'dart:io';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/widgets.dart';

/// dive_obslib Example
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var n = 0;
  ProcessSignal.sigint.watch().listen((signal) {
    print(" caught ${++n} of 3");

    if (n == 3) {
      exit(0);
    }
  });

  await setupOBS();
}

Future<bool> setupOBS() async {
  bool rv = await obslib.obsStartup();
  if (rv) {
    rv = obslib.startObs(
      1920,
      1080,
      1920,
      1080,
      30000,
      1001,
    );
    if (rv) {
      obslib.audioSetDefaultMonitoringDevice();

      final pointer = obslib.createScene('abc', 'scene 1');

      await Future.delayed(Duration(seconds: 2));

      if (pointer != null) obslib.deleteScene(pointer);
      obslib.shutdown();
    }
  }
  return rv;
}
