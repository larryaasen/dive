import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:dive_obslib/dive_obs_ffi.dart';
import 'package:ffi/ffi.dart';

extension StringExtensions on String {
  ffi.Pointer<ffi.Int8> toInt8() {
    return Utf8.toUtf8(this).cast<ffi.Int8>();
  }
}

extension PointerExtensions<T extends ffi.NativeType> on ffi.Pointer<T> {
  String toStr() {
    if (T == ffi.Int8) {
      return Utf8.fromUtf8(cast<Utf8>());
    }

    throw UnsupportedError('$T unsupported');
  }
}

class DiveObslibFFILoad {
  static DiveObslibFFI loadLib() {
    final _lib = Platform.isAndroid
        ? ffi.DynamicLibrary.open("libobs.0.dylib")
        : ffi.DynamicLibrary.process();
    print("libobs library loaded: ${_lib.toString()}");
    return DiveObslibFFI(_lib);
  }
}
