import 'dart:ffi' as ffi;

// The package ffigen generates code that generates warnings with the Dart
// analyzer, so ignore some of the rules.
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: camel_case_types

/// Dart bindings to obslib
class DiveObslibFFI {
  // ignore: sdk_version_never
  ffi.Pointer<Never> get nullptr => ffi.nullptr;

  /// Holds the Dynamic library.
  final ffi.DynamicLibrary _dylib;

  /// The symbols are looked up in [dynamicLibrary].
  DiveObslibFFI(ffi.DynamicLibrary dynamicLibrary) : _dylib = dynamicLibrary;

  /// Automatically loads all modules from module paths (convenience function)
  void obs_load_all_modules() {
    _obs_load_all_modules ??= _dylib.lookupFunction<_c_obs_load_all_modules,
        _dart_obs_load_all_modules>('obs_load_all_modules');
    return _obs_load_all_modules();
  }

  _dart_obs_load_all_modules _obs_load_all_modules;

  /// Notifies modules that all modules have been loaded.  This function should
  /// be called after all modules have been loaded.
  void obs_post_load_modules() {
    _obs_post_load_modules ??= _dylib.lookupFunction<_c_obs_post_load_modules,
        _dart_obs_post_load_modules>('obs_post_load_modules');
    return _obs_post_load_modules();
  }

  _dart_obs_post_load_modules _obs_post_load_modules;
}

class profiler_name_store extends ffi.Struct {}

typedef _c_obs_load_all_modules = ffi.Void Function();

typedef _dart_obs_load_all_modules = void Function();

typedef _c_obs_post_load_modules = ffi.Void Function();

typedef _dart_obs_post_load_modules = void Function();

/// This class holds the functions that have been removed.
class DiveRemovedObslibFFI {
  /// Holds the Dynamic library.
  final ffi.DynamicLibrary _dylib;

  /// The symbols are looked up in [dynamicLibrary].
  DiveRemovedObslibFFI(ffi.DynamicLibrary dynamicLibrary)
      : _dylib = dynamicLibrary;

  /// Initializes OBS
  ///
  /// @param  locale              The locale to use for modules
  /// @param  module_config_path  Path to module config storage directory
  /// (or NULL if none)
  /// @param  store               The profiler name store for OBS to use or NULL
  ///
  /// *** Do not call this method from Dart because it is required to run on the
  /// *** main thread, and Dart FFI does not run on the main thread.
  int obs_startup(
    ffi.Pointer<ffi.Int8> locale,
    ffi.Pointer<ffi.Int8> module_config_path,
    ffi.Pointer<profiler_name_store> store,
  ) {
    _obs_startup ??=
        _dylib.lookupFunction<_c_obs_startup, _dart_obs_startup>('obs_startup');
    return _obs_startup(
      locale,
      module_config_path,
      store,
    );
  }

  _dart_obs_startup _obs_startup;

  /// Sets base video output base resolution/fps/format.
  ///
  /// @note This data cannot be changed if an output is currently active.
  /// @note The graphics module cannot be changed without fully destroying the
  /// OBS context.
  ///
  /// @param   ovi  Pointer to an obs_video_info structure containing the
  /// specification of the graphics subsystem,
  /// @return       OBS_VIDEO_SUCCESS if successful
  /// OBS_VIDEO_NOT_SUPPORTED if the adapter lacks capabilities
  /// OBS_VIDEO_INVALID_PARAM if a parameter is invalid
  /// OBS_VIDEO_CURRENTLY_ACTIVE if video is currently active
  /// OBS_VIDEO_MODULE_NOT_FOUND if the graphics module is not found
  /// OBS_VIDEO_FAIL for generic failure
  int obs_reset_video(
    ffi.Pointer<obs_video_info> ovi,
  ) {
    _obs_reset_video ??=
        _dylib.lookupFunction<_c_obs_reset_video, _dart_obs_reset_video>(
            'obs_reset_video');
    return _obs_reset_video(
      ovi,
    );
  }

  _dart_obs_reset_video _obs_reset_video;

  /// Sets base audio output format/channels/samples/etc
  ///
  /// @note Cannot reset base audio if an output is currently active.
  int obs_reset_audio(
    ffi.Pointer<obs_audio_info> oai,
  ) {
    _obs_reset_audio ??=
        _dylib.lookupFunction<_c_obs_reset_audio, _dart_obs_reset_audio>(
            'obs_reset_audio');
    return _obs_reset_audio(
      oai,
    );
  }

  _dart_obs_reset_audio _obs_reset_audio;
}

/// Video initialization structure
class obs_video_info extends ffi.Struct {
  /// Graphics module to use (usually "libobs-opengl" or "libobs-d3d11")
  ffi.Pointer<ffi.Int8> graphics_module;

  /// < Output FPS numerator
  @ffi.Uint32()
  int fps_num;

  /// < Output FPS denominator
  @ffi.Uint32()
  int fps_den;

  /// < Base compositing width
  @ffi.Uint32()
  int base_width;

  /// < Base compositing height
  @ffi.Uint32()
  int base_height;

  /// < Output width
  @ffi.Uint32()
  int output_width;

  /// < Output height
  @ffi.Uint32()
  int output_height;

  /// < Output format
  @ffi.Int32()
  int output_format;

  /// Video adapter index to use (NOTE: avoid for optimus laptops)
  @ffi.Uint32()
  int adapter;

  /// Use shaders to convert to different color formats
  @ffi.Uint8()
  int gpu_conversion;

  /// < YUV type (if YUV)
  @ffi.Int32()
  int colorspace;

  /// < YUV range (if YUV)
  @ffi.Int32()
  int range;

  /// < How to scale if scaling
  @ffi.Int32()
  int scale_type;
}

/// Audio initialization structure
class obs_audio_info extends ffi.Struct {
  @ffi.Uint32()
  int samples_per_sec;

  @ffi.Int32()
  int speakers;
}

typedef _c_obs_startup = ffi.Int32 Function(
  ffi.Pointer<ffi.Int8> locale,
  ffi.Pointer<ffi.Int8> module_config_path,
  ffi.Pointer<profiler_name_store> store,
);

typedef _dart_obs_startup = int Function(
  ffi.Pointer<ffi.Int8> locale,
  ffi.Pointer<ffi.Int8> module_config_path,
  ffi.Pointer<profiler_name_store> store,
);

typedef _c_obs_reset_video = ffi.Int32 Function(
  ffi.Pointer<obs_video_info> ovi,
);

typedef _dart_obs_reset_video = int Function(
  ffi.Pointer<obs_video_info> ovi,
);

typedef _c_obs_reset_audio = ffi.Uint8 Function(
  ffi.Pointer<obs_audio_info> oai,
);

typedef _dart_obs_reset_audio = int Function(
  ffi.Pointer<obs_audio_info> oai,
);

abstract class video_format {
  static const int VIDEO_FORMAT_NONE = 0;
  static const int VIDEO_FORMAT_I420 = 1;
  static const int VIDEO_FORMAT_NV12 = 2;
  static const int VIDEO_FORMAT_YVYU = 3;
  static const int VIDEO_FORMAT_YUY2 = 4;
  static const int VIDEO_FORMAT_UYVY = 5;
  static const int VIDEO_FORMAT_RGBA = 6;
  static const int VIDEO_FORMAT_BGRA = 7;
  static const int VIDEO_FORMAT_BGRX = 8;
  static const int VIDEO_FORMAT_Y800 = 9;
  static const int VIDEO_FORMAT_I444 = 10;
  static const int VIDEO_FORMAT_BGR3 = 11;
  static const int VIDEO_FORMAT_I422 = 12;
  static const int VIDEO_FORMAT_I40A = 13;
  static const int VIDEO_FORMAT_I42A = 14;
  static const int VIDEO_FORMAT_YUVA = 15;
  static const int VIDEO_FORMAT_AYUV = 16;
}

abstract class video_colorspace {
  static const int VIDEO_CS_DEFAULT = 0;
  static const int VIDEO_CS_601 = 1;
  static const int VIDEO_CS_709 = 2;
  static const int VIDEO_CS_SRGB = 3;
}

abstract class video_range_type {
  static const int VIDEO_RANGE_DEFAULT = 0;
  static const int VIDEO_RANGE_PARTIAL = 1;
  static const int VIDEO_RANGE_FULL = 2;
}
