import 'package:uuid/uuid.dart';

/// Simple, fast generation of RFC4122 UUIDs
final _uuid = Uuid();

abstract class DiveUuid {
  static String newId() => _uuid.v1();
}
