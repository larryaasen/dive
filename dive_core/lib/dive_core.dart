library dive_core;

import 'dart:ffi' as ffi;
import 'package:riverpod/riverpod.dart';

import 'package:dive_obslib/dive_obs_ffi.dart';
import 'package:dive_obslib/dive_ffi_load.dart';
import 'package:ffi/ffi.dart';

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

/// A callback used by providers to create the value exposed.
///
/// If an exception is thrown within that callback, all attempts at reading
/// the provider associated with the given callback will throw.
///
/// The parameter [ref] can be used to interact with other providers
/// and the life-cycles of this provider.
///
/// See also:
///
/// - [ProviderReference], which exposes the methods to read other providers.
/// - [Provider], a provider that uses [Create] to expose an immutable value.

class DiveCore {
  /// For use with Riverpod
  static ProviderContainer providerContainer;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw ProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }

  DiveObslibFFI _lib;

  int startFFI() {
    _lib = DiveObslibFFILoad.loadLib();

    return _startObs();
  }

  int _startObs() {
    try {
      // final locale = 'en'.toInt8();
      // final rv = _lib.obs_startup(locale, _lib.nullptr, _lib.nullptr);
      // free(locale);
      int rv = 1;

      if (rv == 1) {
        _lib.obs_load_all_modules();
        _lib.obs_post_load_modules();
        if (!_resetVideo()) return 0;
        if (!_resetAudio()) return 0;
        // if (!create_service()) return 0;

      } else {
        print("_startObs: the call to obs_startup failed.");
      }

      return rv;
    } catch (e) {
      print("_startObs: exception: $e");
    }
    return 1;
  }

  static const int cx = 1280;
  static const int cy = 720;

  bool _resetVideo() {
    final ovi = allocate<obs_video_info>().ref
      ..adapter = 0
      ..fps_num = 30000
      ..fps_den = 1001
      ..graphics_module = 'libobs-opengl'.toInt8() //DL_OPENGL
      ..output_format = video_format.VIDEO_FORMAT_RGBA
      ..base_width = cx
      ..base_height = cy
      ..output_width = cx
      ..output_height = cy
      ..colorspace = video_colorspace.VIDEO_CS_DEFAULT;

    int rv = _lib.obs_reset_video(ovi.addressOf);
    if (rv != OBS_VIDEO_SUCCESS) {
      print("Couldn't initialize video: $rv");
      return false; //throw "Couldn't initialize video";
    }
    return true;
  }

  bool _resetAudio() {
    final ai = allocate<obs_audio_info>().ref
      ..samples_per_sec = 48000
      ..speakers = speaker_layout.SPEAKERS_STEREO;
    int rv = _lib.obs_reset_audio(ai.addressOf);
    if (rv == 0) {
      print("Couldn't initialize audio: $rv");
      return false;
    }
    return true;
  }
}

class ProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
