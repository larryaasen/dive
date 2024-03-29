import 'package:uuid/uuid.dart';

/// Simple, fast generation of RFC4122 UUIDs
// ignore: prefer_const_constructors
var _uuid = Uuid();

abstract class DiveUuid {
  static String newId() => _uuid.v1();
}
