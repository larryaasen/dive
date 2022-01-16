// abstract class DiveInputTypeKey {
//   static const IMAGE = "image";
// }

/// The Dive input type definition. There are a few default types inluding
/// [DiveInputType.audio], [DiveInputType.image], [DiveInputType.media], and
/// [DiveInputType.video]. You can also create new custom types to add types
/// to the framework, by return one here [DiveInputProvider.inputTypes].
class DiveInputType {
  final String uuid;
  final String name;

  DiveInputType(this.uuid, this.name);

  /// The default audio input type.
  static DiveInputType get audio =>
      DiveInputType('b3e12428-9406-4d00-995d-a2c09e627d17', 'Audio');

  /// The default image input type.
  static DiveInputType get image =>
      DiveInputType('433a04a4-bbd6-4fa7-9cdd-6dba51246b5f', 'Image');

  /// The default media input type.
  static DiveInputType get media =>
      DiveInputType('c8732afd-557a-4dde-80e0-797734cb5644', 'Media');

  /// The default media input type.
  static DiveInputType get video =>
      DiveInputType('b11c0e88-0726-4889-8853-d801dc6c2c22', 'Video');

  static DiveInputType? fromMap(Map<String, dynamic> map) {
    if (map['uuid'] == null || map['name'] == null) {
      return null;
    }
    DiveInputType(map['uuid'], map['name']);
  }

  @override
  String toString() {
    return "DiveInputType name: $name, uuid: $uuid";
  }
}

class DiveInputTypes {
  DiveInputTypes();

  // TODO: Implement this all() method.
  static Future<List<DiveInputType>> all() async => [];
  // oldlib.inputTypes().map(DiveInputType.fromJson).toList();
}
