library dive_core;

import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';

export 'dive_format.dart';
export 'dive_elements.dart';
export 'dive_input_type.dart';
export 'dive_input.dart';
export 'dive_media_source.dart';
export 'dive_volume_meter.dart';
export 'dive_output.dart';
export 'dive_sources.dart';
export 'dive_system_log.dart';
export 'dive_system_log.dart';
export 'texture_controller.dart';

class DiveCoreResolution {
  final int width;
  final int height;
  const DiveCoreResolution(this.width, this.height);

  String get resolution => "${width}x$height";
  double get aspectRatio => width / height;

  static const r7680_4320 = DiveCoreResolution(7680, 4320);

  /// 4K resolution
  static const r3840_2160 = DiveCoreResolution(3840, 2160);

  /// Full HD resolution
  static const r1920_1080 = DiveCoreResolution(1920, 1080);

  /// HD resolution
  static const r1280_720 = DiveCoreResolution(1280, 720);

  /// 8K resolutions
  static const r8K = r7680_4320;

  /// 4K resolution
  static const UHD = r3840_2160;

  /// 4K resolution
  static const r4K = UHD;

  /// Full HD resolution
  static const FULL_HD = r1920_1080;

  /// Full HD resolution
  static const r1080p = FULL_HD;

  /// HD resolution
  static const HD = r1280_720;

  /// HD resolution
  static const r720p = HD;
}

class DiveCoreAspectRatio {
  final String _sRatio;
  final double _dRatio;

  const DiveCoreAspectRatio(this._sRatio, this._dRatio);

  double get ratio => _dRatio;
  double get toDouble => _dRatio;
  String get text => _sRatio;

  /// HD TV aspect ratio
  static const r16_9 = DiveCoreAspectRatio("16:9", 16 / 9);

  /// SD TV aspect ratio
  static const r4_3 = DiveCoreAspectRatio("4:3", 4 / 3);

  /// Square aspect ratio
  static const r1_1 = DiveCoreAspectRatio("1:1", 1 / 1);

  /// Movie theater aspect ratio
  static const r21_9 = DiveCoreAspectRatio("21:9", 21 / 9);

  /// Old widescreen aspect ratio
  static const r16_10 = DiveCoreAspectRatio("16:10", 16 / 10);

  /// IMAX Film aspect ratio
  static const r14_10 = DiveCoreAspectRatio("14:10", 14 / 10);

  /// IMAX Digital aspect ratio
  static const r19_10 = DiveCoreAspectRatio("19:10", 19 / 10);

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

/// Usage:
///   final core = DiveCore();
///   core.setupOBS(DiveCoreResolution.HD);
///
class DiveCore {
  /// For use with Riverpod
  static ProviderContainer providerContainer;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw DiveCoreProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }

  void setupOBS(DiveCoreResolution resolution) {
    obslib.startObs(resolution.width, resolution.height);
  }
}

class DiveCoreProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
