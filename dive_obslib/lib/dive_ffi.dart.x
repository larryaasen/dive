import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

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

class obslib_ffi {
  DynamicLibrary _libobsLibrary;

  void loadLib() {
    _libobsLibrary = Platform.isAndroid
        ? DynamicLibrary.open("libobs.0.dylib")
        : DynamicLibrary.process();
    print("libobs library loaded: ${_libobsLibrary.toString()}");

    final obs_startup = _libobsLibrary
        .lookupFunction<obs_startup_native, obs_startup_dart>('obs_startup');

    final locale = Utf8.toUtf8('en');
    try {
      final int rv = obs_startup(locale, nullptr, nullptr);
      assert(rv > 0, 'obs_startup failed');
    } catch (e) {
      print(e);
    }
    free(locale);

    final obs_load_all_modules = _libobsLibrary
        .lookupFunction<ffi_void_native, ffi_void>('obs_load_all_modules');
    final obs_post_load_modules = _libobsLibrary
        .lookupFunction<ffi_void_native, ffi_void>('obs_post_load_modules');
    obs_load_all_modules();
    obs_post_load_modules();
  }
}
