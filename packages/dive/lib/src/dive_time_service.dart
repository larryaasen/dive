// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:riverpod/riverpod.dart';

import 'dive_core.dart';
import 'dive_format.dart';

class DiveTimeServiceState extends Equatable {
  const DiveTimeServiceState(this.now, this.nowFormatted);

  final DateTime now;
  final String nowFormatted;

  @override
  List<Object?> get props => [now, nowFormatted];
}

/// A wall clock timer service.
class DiveTimeService {
  /// Create a Riverpod provider to maintain the state.
  final provider = StateProvider<DiveTimeServiceState>((ref) {
    final time = DateTime.now();
    return DiveTimeServiceState(time, _formatted(time));
  });

  /// Update the state.
  void _updateState(DiveTimeServiceState newState) {
    final notifier = DiveCore.providerContainer.read(provider.notifier);
    if (notifier.state != newState) {
      notifier.state = newState;
    }
  }

  /// Initialize this service.
  void initialize() {
    Timer.periodic(const Duration(seconds: 1), _onTimer);
  }

  /// The timer went off.
  void _onTimer(Timer timer) {
    final time = DateTime.now();
    _updateState(DiveTimeServiceState(time, _formatted(time)));
  }

  /// Format the time into a [String].
  static String _formatted(DateTime time) => DiveFormat.formatterTime.format(time);
}
