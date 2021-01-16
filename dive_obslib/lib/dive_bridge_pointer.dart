import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Track of all created pointers where the key is a tracking UUID and the
/// value is an object pointer.
class DiveBridgePointer {
  final String trackingUuid;
  final dynamic pointer;
  DiveBridgePointer(this.trackingUuid, this.pointer);

  void releasePointer() {
    free(pointer as ffi.Pointer<ffi.Int8>);
  }
}
