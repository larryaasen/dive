class DiveDevice {
  final String id;
  final String mediaType;
  final String name;

  DiveDevice({this.id, this.mediaType, this.name});

  static DiveDevice fromJson(dynamic json) {
    return DiveDevice(
      id: json['id'],
      mediaType: json['mediaType'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return "name: $name, id: $id, mediaType: $mediaType";
  }
}
