// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dive_core/dive_core.dart';
import 'package:dive_widgets/dive_widgets.dart';
import 'package:flutter/material.dart';

import 'audio_simulator.dart';
import 'dive_caster.dart';

void main() {
  // runApp(const MyApp());
  runApp(const DiveCasterApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dive Audio Meter example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;
  DiveAudioMeterValues _input = const DiveAudioMeterValues();
  final _simulator = AudioSimulator();
  double _peak = DiveAudioMeterConst.minLevel;

  @override
  void initState() {
    const updateInterval = Duration(milliseconds: 100);
    const simulationDuration = Duration(seconds: 50);

    // Start the simulation with updates every 100ms, range from -60 to 0 dB
    var magnitudeStream = _simulator.startMagnitudeSimulation(
      interval: updateInterval,
      minMagnitude: DiveAudioMeterConst.minLevel,
      maxMagnitude: DiveAudioMeterConst.maxLevel,
      initialMagnitude: DiveAudioMeterConst.minLevel,
    );

    // Listen to the simulator stream.
    magnitudeStream.listen(
      (magnitude) {
        if (magnitude > _peak) _peak = magnitude;
        final state = DiveAudioMeterValues(
          channelCount: 2,
          magnitude: [magnitude, magnitude],
          peak: [_peak, _peak],
          peakHold: const [
            DiveAudioMeterConst.minLevel,
            DiveAudioMeterConst.minLevel
          ], // const [-9.778120040893555],
          noSignal: false,
        );
        setState(() => _input = state);
        print('$magnitude $_peak');
      },
      onDone: () => print('Simulation stopped.'),
    );

    // Stop the simulation after 5 seconds
    Future.delayed(simulationDuration).then((value) => _simulator.stop());

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    _simulator.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: RepaintBoundary(
                child: DiveAudioMeter(
                  values: DiveAudioMeterValues.noSignal(2),
                  thickness: 10,
                  vertical: false,
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            SizedBox(
              width: 300,
              child: RepaintBoundary(
                child: DiveAudioMeter(
                  values: _input,
                  thickness: 8,
                  vertical: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
