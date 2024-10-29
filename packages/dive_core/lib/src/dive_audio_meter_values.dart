// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:equatable/equatable.dart';

class DiveAudioMeterConst {
  /// Audio meter minumum level (dB)
  static const double minLevel = -60.0;

  /// Audio meter maximum level (dB)
  static const double maxLevel = 0.0;
}

/// The input values for an audio meter.
class DiveAudioMeterValues extends Equatable {
  /// Creates the input values for an audio meter.
  const DiveAudioMeterValues({
    this.channelCount = 0,
    this.magnitude,
    this.peak,
    this.peakHold,
    this.noSignal = false,
  });

  /// The channel count. There can be many audio channels. For left and right, this value should be 2.
  /// For mono, or a signle channel, this value should be 1.
  final int channelCount;

  /// The magnitude of the audio signal. It will be displayed as a thin black line.
  final List<double>? magnitude;

  /// The peak.
  final List<double>? peak;

  /// The peak and hold.
  /// If you do not want to use this value, set it to [DiveAudioMeterConst.minLevel].
  final List<double>? peakHold;

  /// no signal
  final bool noSignal;

  DiveAudioMeterValues copyWith({
    channelCount,
    magnitude,
    peak,
    peakHold,
    noSignal,
  }) {
    return DiveAudioMeterValues(
      channelCount: channelCount ?? this.channelCount,
      magnitude: magnitude ?? this.magnitude,
      peak: peak ?? this.peak,
      peakHold: peakHold ?? this.peakHold,
      noSignal: noSignal ?? this.noSignal,
    );
  }

  @override
  List<Object?> get props => [
        channelCount,
        magnitude,
        peak,
        peakHold,
        noSignal,
      ];

  factory DiveAudioMeterValues.min(int channelCount) {
    return DiveAudioMeterValues(
      channelCount: channelCount,
      magnitude: List.generate(
          channelCount, (int index) => DiveAudioMeterConst.minLevel),
      peak: List.generate(
          channelCount, (int index) => DiveAudioMeterConst.minLevel),
      peakHold: List.generate(
          channelCount, (int index) => DiveAudioMeterConst.minLevel),
    );
  }

  factory DiveAudioMeterValues.noSignal(int channelCount) {
    return DiveAudioMeterValues.min(channelCount).copyWith(noSignal: true);
  }
}
