import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/widgets.dart';

/// dive_obslib Example
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    }
  }
  return rv;
}
