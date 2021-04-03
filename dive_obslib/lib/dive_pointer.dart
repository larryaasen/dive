import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Track of all created pointers where the key is a tracking UUID and the
/// value is an object pointer.
class DivePointer {
  DivePointer(this.trackingUuid, this.pointer);

  final String trackingUuid;
  final dynamic pointer;

  int toInt() {
    try {
      return pointer.address;
    } catch (e) {
      print("DivePointer exception $e");
      return 0;
    }
  }

  void releasePointer() {
    free(pointer as ffi.Pointer<ffi.Int8>);
  }

  int get address => (pointer as ffi.Pointer).address;
}
