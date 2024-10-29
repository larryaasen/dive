// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:dive_core/dive_core.dart';

class AudioSimulator {
  AudioSimulator({
    this.magnitudeSmoothingFactor = 0.3,
  });

  final Random _random = Random();
  late double _lastMagnitude;
  final double magnitudeSmoothingFactor;

  StreamController<double>? _magnitudeController;
  Timer? _timer;
  bool _isRunning = false;
  late double _minMagnitude;
  late double _maxMagnitude;

  // Generates a simulated audio magnitude between _minMagnitude and _maxMagnitude
  double _generateMagnitude() {
    final normalizedChange =
        (_random.nextDouble() - 0.5) * magnitudeSmoothingFactor;
    final magnitudeRange = _maxMagnitude - _minMagnitude;
    final change = normalizedChange * magnitudeRange;
    _lastMagnitude += change;
    _lastMagnitude = _lastMagnitude.clamp(_minMagnitude, _maxMagnitude);
    return _lastMagnitude;
  }

  // Starts the audio magnitude simulation
  Stream<double> startMagnitudeSimulation({
    Duration interval = const Duration(milliseconds: 50),
    double minMagnitude = 0.0,
    double maxMagnitude = 1.0,
    double? initialMagnitude,
  }) {
    if (_isRunning) {
      throw StateError('Simulation is already running');
    }

    if (minMagnitude >= maxMagnitude) {
      throw ArgumentError('minMagnitude must be less than maxMagnitude');
    }

    _minMagnitude = minMagnitude;
    _maxMagnitude = maxMagnitude;
    _lastMagnitude = initialMagnitude ?? (minMagnitude + maxMagnitude) / 2;

    _magnitudeController = StreamController<double>(
      onCancel: stop,
    );
    _isRunning = true;

    _timer = Timer.periodic(interval, (_) {
      if (_magnitudeController?.isClosed == false) {
        _magnitudeController?.add(_generateMagnitude());
      }
    });

    return _magnitudeController!.stream;
  }

  // Stops the audio simulation
  void stop() {
    _timer?.cancel();
    _magnitudeController?.close();
    _isRunning = false;
  }

  // Checks if the simulation is currently running
  bool get isRunning => _isRunning;
}

void main() async {
  const simulationDuration = Duration(seconds: 2);
  const updateInterval = Duration(milliseconds: 100);

  final simulator = AudioSimulator();

  print('Starting audio magnitude simulation (range: -60 to 0 dB):');

  // Start the simulation with updates every 100ms, range from -60 to 0 dB
  var magnitudeStream = simulator.startMagnitudeSimulation(
    interval: updateInterval,
    minMagnitude: DiveAudioMeterConst.minLevel,
    maxMagnitude: DiveAudioMeterConst.maxLevel,
    initialMagnitude: DiveAudioMeterConst.minLevel,
  );

  // Listen to the stream for 2 seconds
  magnitudeStream.listen(
    (magnitude) => print('${magnitude.toStringAsFixed(2)} dB'),
    onDone: () => print('Simulation stopped.'),
  );

  // Stop the simulation after 2 seconds
  await Future<void>.delayed(simulationDuration);
  simulator.stop();
}
