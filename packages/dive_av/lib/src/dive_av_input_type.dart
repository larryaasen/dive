// Copyright (c) 2024 Larry Aasen. All rights reserved.

/// An input type.
class DiveAVInputType {
  /// Creates an input type.
  DiveAVInputType(
      {this.localizedName, required this.uniqueID, required this.typeId});

  /// The input name, such as `FaceTime HD Camera (Built-in)`.
  final String? localizedName;

  /// The input id, such as `0x8020000005ac8514`.
  final String uniqueID;

  /// The input type id, such as `video` or `audio`.
  final String typeId;

  static DiveAVInputType fromMap(dynamic map) {
    return DiveAVInputType(
      uniqueID: map['uniqueID'],
      localizedName: map['localizedName'],
      typeId: map['type_id'],
    );
  }

  @override
  String toString() {
    return "DiveAVInputType name: $uniqueID, id: $localizedName, typeId: $typeId";
  }
}
