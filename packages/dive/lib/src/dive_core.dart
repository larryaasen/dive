// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

// TODO: Review use of Riverpod.

/// Configure a Dive app.
void configDiveApp() {
  // We need the binding to be initialized before calling runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Configure globally for all Equatable instances via EquatableConfig
  EquatableConfig.stringify = true;
}

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

  /// Full HD resolution: 1920x1080
  static const FULL_HD = r1920_1080;

  /// Full HD resolution: 1920x1080
  static const r1080p = FULL_HD;

  /// HD resolution: 1280x720
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
      if (input.width == resolution.width && input.height == resolution.height) {
        foundIndex = index;
        return;
      }
      index++;
    });
    return foundIndex;
  }

  /// Find the name of the resolution with this [width] and [height].
  static String? nameOf(int width, int height) {
    for (var resolution in DiveCoreResolution.all) {
      if (width == resolution.width && height == resolution.height) {
        return resolution.name;
      }
    }
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

class MonitoringType {
  static const none = 0;
  static const monitorOnly = 1;
  static const monitorAndOutput = 2;
}

/// Monitoring Types
enum DiveCoreMonitoringType { none, monitorOnly, monitorAndOutput }

/// An audio level.
class DiveCoreLevel {
  final double _level;

  /// Get the level in dB.
  double get dB => obslib.toDb(_level);

  /// Get the level.
  void get level => _level;

  /// Creates an instance of [DiveCoreLevel].
  /// To create an instance using dB, use [DiveCoreLevel.dB].
  DiveCoreLevel(double level) : _level = level;

  /// Creates an instance of [DiveCoreLevel] using a level in dB.
  factory DiveCoreLevel.dB(double levelDb) => DiveCoreLevel(obslib.fromDb(levelDb));
}

/// Usage:
///   configDiveApp();
///   final core = DiveCore();
///   core.setupOBS(DiveCoreResolution.HD);
///
class DiveCore {
  /// For use with Riverpod
  static final providerContainer = ProviderContainer();
  static ProviderContainer get container => providerContainer;

  Future<bool> setupOBS(
    DiveCoreResolution baseResolution, {
    DiveCoreResolution? outResolution,
    DiveCoreFPS fps = DiveCoreFPS.fps29_97,
  }) async {
    bool rv = await obslib.obsStartup();
    if (rv) {
      outResolution = outResolution ?? baseResolution;
      rv = obslib.startObs(
        baseResolution.width,
        baseResolution.height,
        outResolution.width,
        outResolution.height,
        fps.numerator,
        fps.denominator,
      );
      if (rv) {
        obslib.audioSetDefaultMonitoringDevice();
      }
    }
    return rv;
  }

  void shutdown() {
    obslib.shutdown();
  }
}

class DiveCoreProviderContainerException implements Exception {
  @override
  String toString() => 'DiveCore.providerContainer should not be null.';
}

/// Extention methods on double.
extension DiveDoubleRound on double {
  /// Round a double to fixed places.
  double roundAsFixed(int places) => _roundAsFixed(this, places);
}

/// Round a double to fixed places.
double _roundAsFixed(double value, int places) {
  double mod = pow(10.0, places) as double;
  return ((value * mod).round().toDouble() / mod);
}
