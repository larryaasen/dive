library dive_core;

import 'package:riverpod/riverpod.dart';

import 'package:dive_obslib/dive_ffi.dart';
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
      } else {
        print("_startObs: the call to obs_startup failed.");
      }

      return rv;
    } catch (e) {
      print("_startObs: exception: $e");
    }
    return 0;
  }
}

class ProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
