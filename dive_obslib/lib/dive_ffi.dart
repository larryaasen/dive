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

  /// Initializes OBS
  ///
  /// @param  locale              The locale to use for modules
  /// @param  module_config_path  Path to module config storage directory
  /// (or NULL if none)
  /// @param  store               The profiler name store for OBS to use or NULL
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

class profiler_name_store extends ffi.Struct {}

typedef _c_obs_load_all_modules = ffi.Void Function();

typedef _dart_obs_load_all_modules = void Function();

typedef _c_obs_post_load_modules = ffi.Void Function();

typedef _dart_obs_post_load_modules = void Function();

///============================

/*****
// EXPORT bool obs_startup(const char *locale, const char *module_config_path,
//			profiler_name_store_t *store);

typedef obs_startup_native = Int32 Function(
  Pointer<Utf8> locale,
  Pointer<Utf8> module_config_path,
  Pointer<Utf8> store,
);

typedef obs_startup_dart = int Function(
  Pointer<Utf8> locale,
  Pointer<Utf8> module_config_path,
  Pointer<Utf8> store,
);

typedef ffi_void_native = Void Function();
typedef ffi_void = void Function();

// EXPORT int obs_reset_video(struct obs_video_info *ovi);

class obs_video_info extends Struct {
  @Double()
  double latitude;

  @Double()
  double longitude;

  factory obs_video_info.allocate(double latitude, double longitude) =>
      allocate<obs_video_info>().ref
        ..latitude = latitude
        ..longitude = longitude;
}

class DiveObslibFFI_first {
  DynamicLibrary _lib;

  void loadLib() {
    _lib = Platform.isAndroid
        ? DynamicLibrary.open("libobs.0.dylib")
        : DynamicLibrary.process();
    print("libobs library loaded: ${_lib.toString()}");

    final obs_startup = _lib
        .lookupFunction<obs_startup_native, obs_startup_dart>('obs_startup');

    final locale = Utf8.toUtf8('en');
    try {
      final int rv = obs_startup(locale, nullptr, nullptr);
      assert(rv > 0, 'obs_startup failed');
    } catch (e) {
      print(e);
    }
    free(locale);

    final obs_load_all_modules =
        _lib.lookupFunction<ffi_void_native, ffi_void>('obs_load_all_modules');
    final obs_post_load_modules =
        _lib.lookupFunction<ffi_void_native, ffi_void>('obs_post_load_modules');
    obs_load_all_modules();
    obs_post_load_modules();
  }
}
 */
