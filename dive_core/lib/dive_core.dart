library dive_core;

import 'package:dive_obslib/dive_obs_bridge.dart';
import 'package:riverpod/riverpod.dart';

export 'dive_format.dart';
export 'dive_input_type.dart';
export 'dive_input.dart';
export 'dive_media_source.dart';
export 'dive_output.dart';
export 'dive_plugin.dart';
export 'dive_sources.dart';
export 'dive_system_log.dart';
export 'dive_system_log.dart';
export 'texture_controller.dart';

DiveObsBridge obsControl;

/// Usage:
///   final core = DiveCore();
///   core.setupOBS();
///
class DiveCore {
  /// For use with Riverpod
  static ProviderContainer providerContainer;

  /// Provides access to DiveObsBridge
  static DiveObsBridge get bridge => obsControl;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw ProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }

  void setupOBS() {
    if (obsControl != null) return;

    obsControl = DiveObsBridge();
    obsControl.startObs();
  }
}

class ProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
