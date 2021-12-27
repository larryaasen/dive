library dive_core;

import 'dart:math';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';

export 'dive_format.dart';
export 'dive_elements.dart';
export 'dive_input_type.dart';
export 'dive_input.dart';
export 'dive_media_source.dart';
export 'dive_audio_meter_source.dart';
export 'dive_output.dart';
export 'dive_scene.dart';
export 'dive_sources.dart';
export 'dive_system_log.dart';
export 'dive_system_log.dart';
export 'dive_transform_info.dart';
export 'dive_uuid.dart';
export 'texture_controller.dart';

/*
  TODO: Review use of Riverpod.
  
  Notes:
    HookWidget;
    flutter_hooks;
    useProvider(elements.stateProvider);
    useMemoized();
    Riverpod Discord.

    Flutter Snippets ad-on;
    Dart Data Class Generator ad-on;
    dart-import ad-on;
*/

/// The various different frame rates (FPS).
class DiveCoreFPS {
  const DiveCoreFPS(this.frameRate, this.numerator, this.denominator);

  factory DiveCoreFPS.values(int numerator, int denominator) => DiveCoreFPS(
        (numerator / denominator).roundAsFixed(2),
        numerator,
        denominator,
      );

  final double frameRate;
  final int numerator;
  final int denominator;

  /// Frame Rate 59.94 FPS.
  static const fps59_94 = DiveCoreFPS(59.94, 60000, 1001);

  /// Frame Rate 29.97 FPS.
  static const fps29_97 = DiveCoreFPS(29.97, 30000, 1001);

  /// A list of all of the predefined items in [DiveCoreFPS].
  static const all = [fps59_94, fps29_97];

  /// Find the index of [input] in all of the items in [DiveCoreFPS].
  static int indexOf(DiveCoreFPS input) {
    int foundIndex = -1;
    var index = 0;
    DiveCoreFPS.all.forEach((fps) {
      if (input.frameRate == fps.frameRate) {
        foundIndex = index;
        return;
      }
      index++;
    });
    return foundIndex;
  }

  @override
  String toString() => "frameRate=$frameRate";
}

/// The various different video resolutions.
class DiveCoreResolution {
  const DiveCoreResolution(this.name, this.width, this.height);

  final String name;
  final int width;
  final int height;

  String get resolution => "${width}x$height ($name)";
  double get aspectRatio => width / height;

  static const r7680_4320 = DiveCoreResolution('8K', 7680, 4320);

  /// 4K resolution
  static const r3840_2160 = DiveCoreResolution('4K UHD', 3840, 2160);

  /// Full HD resolution
  static const r1920_1080 = DiveCoreResolution('Full HD', 1920, 1080);

  /// HD resolution
  static const r1280_720 = DiveCoreResolution('HD', 1280, 720);

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

  /// A list of all of the predefined items in [DiveCoreResolution].

  static const all = [r8K, UHD, FULL_HD, HD];

  /// Find the index of [input] in all of the items in [DiveCoreResolution].
  static int indexOf(DiveCoreResolution input) {
    int foundIndex = -1;
    var index = 0;
    DiveCoreResolution.all.forEach((resolution) {
      if (input.width == resolution.width &&
          input.height == resolution.height) {
        foundIndex = index;
        return;
      }
      index++;
    });
    return foundIndex;
  }

  /// Find the name of the resolution with this [width] and [height].
  static String nameOf(int width, int height) {
    DiveCoreResolution.all.forEach((resolution) {
      if (width == resolution.width && height == resolution.height) {
        return resolution.name;
      }
    });
    return null;
  }
}

/// Aspect ratios.
class DiveCoreAspectRatio {
  const DiveCoreAspectRatio(this._sRatio, this._dRatio);

  final String _sRatio;
  final double _dRatio;

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

  static bool get initialized => DiveCore.providerContainer != null;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw DiveCoreProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }

  void setupOBS(
    DiveCoreResolution baseResolution, {
    DiveCoreResolution outResolution,
    DiveCoreFPS fps = DiveCoreFPS.fps29_97,
  }) {
    outResolution = outResolution ?? baseResolution;
    obslib.startObs(
      baseResolution.width,
      baseResolution.height,
      outResolution.width,
      outResolution.height,
      fps.numerator,
      fps.denominator,
    );
  }
}

class DiveCoreProviderContainerException implements Exception {
  String toString() => 'DiveCore.providerContainer should not be null.';
}

extension DoubleRound on double {
  double roundAsFixed(int places) {
    double mod = pow(10.0, places);
    return ((this * mod).round().toDouble() / mod);
  }
}

double roundAsFixed(double value, int places) {
  double mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}
