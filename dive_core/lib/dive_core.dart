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

class _DiveCoreResolution {
  final int width;
  final int height;
  const _DiveCoreResolution(this.width, this.height);

  String get resolution => "${width}x$height";
  double get aspectRatio => width / height;
}

abstract class DiveCoreResolution {
  static const r7680_4320 = _DiveCoreResolution(7680, 4320);
  static const r3840_2160 = _DiveCoreResolution(3840, 2160);
  static const r1920_1080 = _DiveCoreResolution(1920, 1080);
  static const r1280_720 = _DiveCoreResolution(1280, 720);

  static const r8K = r7680_4320;

  static const UHD = r3840_2160;
  static const r4K = UHD;

  static const FULL_HD = r1920_1080;
  static const r1080p = FULL_HD;

  static const HD = r1280_720;
  static const r720p = HD;
}

class _DiveCoreAspectRatio {
  final String _sRatio;
  final double _dRatio;

  const _DiveCoreAspectRatio(this._sRatio, this._dRatio);

  double get ratio => _dRatio;
  double get toDouble => _dRatio;
  String toString() => _sRatio;
}

/// Various popular aspect ratios.
abstract class DiveCoreAspectRatio {
  /// HD TV aspect ratio
  static const r16_9 = _DiveCoreAspectRatio("16:9", 16 / 9);

  /// SD TV aspect ratio
  static const r4_3 = _DiveCoreAspectRatio("4:3", 4 / 3);

  /// Square aspect ratio
  static const r1_1 = _DiveCoreAspectRatio("1:1", 1 / 1);

  /// Movie theater aspect ratio
  static const r21_9 = _DiveCoreAspectRatio("21:9", 21 / 9);

  /// Old widescreen aspect ratio
  static const r16_10 = _DiveCoreAspectRatio("16:10", 16 / 10);

  /// IMAX Film aspect ratio
  static const r14_10 = _DiveCoreAspectRatio("14:10", 14 / 10);

  /// IMAX Digital aspect ratio
  static const r19_10 = _DiveCoreAspectRatio("19:10", 19 / 10);

  /// HD TV aspect ratio
  static const HD = r16_9;

  /// SD TV aspect ratio
  static const SD = r4_3;

  /// Movie theater aspect ratio
  static const MOVIE = r21_9;

  /// IMAX Film aspect ratio
  static const IMAX_FILM = r14_10;

  /// IMAX Digital aspect ratio
  static const IMAX_DIGITAL = r19_10;
}

DiveObsBridge obsBridge;

/// Usage:
///   final core = DiveCore();
///   core.setupOBS();
///
class DiveCore {
  /// For use with Riverpod
  static ProviderContainer providerContainer;

  /// Provides access to DiveObsBridge
  static DiveObsBridge get bridge => obsBridge;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw ProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }

  void setupOBS() {
    if (obsBridge != null) return;

    obsBridge = DiveObsBridge();
    obsBridge.startObs();
  }
}

class ProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
