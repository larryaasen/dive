// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:dive_obslib/dive_obslib.dart';

import 'dive_core.dart';

enum DiveVideoFormat {
  VIDEO_FORMAT_NONE,

  /* planar 420 format */
  VIDEO_FORMAT_I420,
  /* three-plane */
  VIDEO_FORMAT_NV12,
  /* two-plane, luma and packed chroma */

  /* packed 422 formats */
  VIDEO_FORMAT_YVYU,
  VIDEO_FORMAT_YUY2,
  /* YUYV */
  VIDEO_FORMAT_UYVY,

  /* packed uncompressed formats */
  VIDEO_FORMAT_RGBA,
  VIDEO_FORMAT_BGRA,
  VIDEO_FORMAT_BGRX,
  VIDEO_FORMAT_Y800,
  /* grayscale */

  /* planar 4:4:4 */
  VIDEO_FORMAT_I444,

  /* more packed uncompressed formats */
  VIDEO_FORMAT_BGR3,

  /* planar 4:2:2 */
  VIDEO_FORMAT_I422,

  /* planar 4:2:0 with alpha */
  VIDEO_FORMAT_I40A,

  /* planar 4:2:2 with alpha */
  VIDEO_FORMAT_I42A,

  /* planar 4:4:4 with alpha */
  VIDEO_FORMAT_YUVA,

  /* packed 4:4:4 with alpha */
  VIDEO_FORMAT_AYUV,
}

class DiveVideoInfo {
  /// Graphics module to use (usually "libobs-opengl" or "libobs-d3d11")
  final String? graphicsModule;

  /// < Output FPS
  final DiveCoreFPS? fps;

  /// < Base compositing resolution
  final DiveCoreResolution? baseResolution;

  /// < Output resolution
  final DiveCoreResolution? outputResolution;

  /// < Output format
  final DiveVideoFormat? outputFormat;

  /// Video adapter index to use (NOTE: avoid for optimus laptops)
  final int? adapter;

  /// Use shaders to convert to different color formats
  final bool? gpuConversion;

  /// < YUV type (if YUV)
  final int? colorspace; // TODO: Use enum

  /// < YUV range (if YUV)
  final int? range; // TODO: Use enum

  /// < How to scale if scaling
  final int? scaleType; // TODO: Use enum

  DiveVideoInfo({
    this.graphicsModule,
    this.fps,
    this.baseResolution,
    this.outputResolution,
    this.outputFormat,
    this.adapter,
    this.gpuConversion,
    this.colorspace,
    this.range,
    this.scaleType,
  });

  DiveVideoInfo copyWith({
    String? graphicsModule,
    int? fps,
    int? baseResolution,
    int? outputResolution,
    DiveVideoFormat? outputFormat,
    int? adapter,
    bool? gpuConversion,
    int? colorspace,
    int? range,
    int? scaleType,
  }) {
    return DiveVideoInfo(
      graphicsModule: graphicsModule ?? this.graphicsModule,
      fps: fps as DiveCoreFPS? ?? this.fps,
      baseResolution: baseResolution as DiveCoreResolution? ?? this.baseResolution,
      outputResolution: outputResolution as DiveCoreResolution? ?? this.outputResolution,
      outputFormat: outputFormat ?? this.outputFormat,
      adapter: adapter ?? this.adapter,
      gpuConversion: gpuConversion ?? this.gpuConversion,
      colorspace: colorspace ?? this.colorspace,
      range: range ?? this.range,
      scaleType: scaleType ?? this.scaleType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'graphicsModule': graphicsModule,
      'fps': fps,
      'baseResolution': baseResolution,
      'outputResolution': outputResolution,
      'outputFormat': outputFormat,
      'adapter': adapter,
      'gpuConversion': gpuConversion,
      'colorspace': colorspace,
      'range': range,
      'scaleType': scaleType,
    };
  }

  factory DiveVideoInfo.fromMap(Map<String, dynamic> map) {
    return DiveVideoInfo(
      graphicsModule: map['graphicsModule'],
      fps: map['fps'],
      baseResolution: map['baseResolution'],
      outputResolution: map['outputResolution'],
      outputFormat: map['outputFormat'],
      adapter: map['adapter'],
      gpuConversion: map['gpuConversion'],
      colorspace: map['colorspace'],
      range: map['range'],
      scaleType: map['scaleType'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DiveVideoInfo.fromJson(String source) => DiveVideoInfo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DiveVideoInfo(graphicsModule: $graphicsModule, fpsNum: $fps, baseResolution: $baseResolution, outputResolution: $outputResolution, outputFormat: $outputFormat, adapter: $adapter, gpuConversion: $gpuConversion, colorspace: $colorspace, range: $range, scaleType: $scaleType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiveVideoInfo &&
        other.graphicsModule == graphicsModule &&
        other.fps == fps &&
        other.baseResolution == baseResolution &&
        other.outputResolution == outputResolution &&
        other.outputFormat == outputFormat &&
        other.adapter == adapter &&
        other.gpuConversion == gpuConversion &&
        other.colorspace == colorspace &&
        other.range == range &&
        other.scaleType == scaleType;
  }

  @override
  int get hashCode {
    return graphicsModule.hashCode ^
        fps.hashCode ^
        baseResolution.hashCode ^
        outputResolution.hashCode ^
        outputFormat.hashCode ^
        adapter.hashCode ^
        gpuConversion.hashCode ^
        colorspace.hashCode ^
        range.hashCode ^
        scaleType.hashCode;
  }

  /// Get the video info.
  static DiveVideoInfo? get() {
    final videoInfo = obslib.videoGetInfo();
    if (videoInfo == null) return null;

    final fps = DiveCoreFPS.values(videoInfo['fps_num'], videoInfo['fps_den']);
    final baseRes = DiveCoreResolution(
      DiveCoreResolution.nameOf(videoInfo['base_width'], videoInfo['base_height']) ?? '',
      videoInfo['base_width'],
      videoInfo['base_height'],
    );
    final outputRes = DiveCoreResolution(
      DiveCoreResolution.nameOf(videoInfo['output_width'], videoInfo['output_height']) ?? '',
      videoInfo['output_width'],
      videoInfo['output_height'],
    );
    return DiveVideoInfo(
      graphicsModule: videoInfo['graphics_module'],
      fps: fps,
      baseResolution: baseRes,
      outputResolution: outputRes,
      outputFormat: DiveVideoFormat.values[videoInfo['output_format']],
      adapter: videoInfo['adapter'],
      gpuConversion: videoInfo['gpu_conversion'],
      colorspace: videoInfo['colorspace'],
      range: videoInfo['range'],
      scaleType: videoInfo['scale_type'],
    );
  }

  /// Change the frame rate of the output video.
  static Future<bool> changeFrameRate(DiveCoreFPS frameRate) async {
    final rv = await obslib.changeFrameRate(frameRate.numerator, frameRate.denominator);
    return rv;
  }

  /// Change the base and output resolution of the output video.
  static Future<bool> changeResolution(DiveCoreResolution base, DiveCoreResolution output) async {
    final rv = await obslib.changeResolution(base.width, base.height, output.width, output.height);
    return rv;
  }
}
