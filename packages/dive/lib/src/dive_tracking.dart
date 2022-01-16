import 'dive_uuid.dart';

abstract class DiveTracking {
  /// A RFC4122 V1 UUID (time-based)
  final String _trackingUUID;

  /// A RFC4122 V1 UUID (time-based)
  String get trackingUUID => _trackingUUID;

  DiveTracking() : _trackingUUID = DiveUuid.newId();
}

abstract class DiveNamedTracking {
  final String? name;

  DiveNamedTracking({this.name});
}
