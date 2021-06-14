import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Wrap an obslib pointer in a Dart class.
class DivePointer {
  DivePointer(this.trackingUuid, this.pointer);

  final String trackingUuid; // TODO: do we really need this trackingUuid?
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
    calloc.free(pointer as ffi.Pointer<ffi.Int8>);
  }

  int get address => (pointer as ffi.Pointer).address;
}

class DivePointerData extends DivePointer {
  DivePointerData(dynamic pointer) : super(null, pointer);
}

class DivePointerSceneItem extends DivePointer {
  DivePointerSceneItem(dynamic pointer) : super(null, pointer);
}
