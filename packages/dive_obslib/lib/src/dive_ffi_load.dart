import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'dive_obs_ffi.dart';

List<ffi.Pointer<ffi.Int8>> _int8s = [];

extension Int8Extensions on ffi.Pointer<ffi.Int8> {
  String? get string => StringExtensions.fromInt8(this);
}

extension StringExtensions on String {
  static String? fromInt8(ffi.Pointer<ffi.Int8> pointer) {
    return pointer.address == 0 ? null : pointer.cast<Utf8>().toDartString();
  }

  ffi.Pointer<ffi.Int8> toInt8() => this.toNativeUtf8().cast<ffi.Int8>();

  /// Convert String to Int8, store in private list, and return Int8.
  ffi.Pointer<ffi.Int8> int8() {
    final i8 = toInt8();
    _int8s.add(i8);
    return i8;
  }

  /// Free all allocated Int8s in private list.
  static void freeInt8s() {
    _int8s.forEach((element) => calloc.free(element));
    _int8s.clear();
  }
}

extension PointerExtensions<T extends ffi.NativeType> on ffi.Pointer<T> {
  String toStr() {
    if (T == ffi.Int8) {
      throw UnsupportedError('$T unsupported');
      // return Utf8.fromUtf8(cast<Utf8>());
    }

    throw UnsupportedError('$T unsupported');
  }
}

class DiveObslibFFILoad {
  /// Load the libobs library using FFI.
  static DiveObslibFFI loadLib() {
    final lib = Platform.isAndroid ? ffi.DynamicLibrary.open("libobs.0.dylib") : ffi.DynamicLibrary.process();
    print("libobs library loaded: ${lib.toString()}");
    return DiveObslibFFI(lib);
  }
}
