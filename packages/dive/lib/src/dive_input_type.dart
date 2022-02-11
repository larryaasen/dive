/// The Dive input type definition. There are a few default types inluding
/// [DiveInputType.audio], [DiveInputType.image], [DiveInputType.media], and
/// [DiveInputType.video]. You can also create new custom types to add types
/// to the framework, by returning one here [DiveInputProvider.inputTypes].
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

  /// The default text input type.
  static DiveInputType get text =>
      DiveInputType('e2621522-67a9-4747-becb-01e62b2920c6', 'Text');

  /// The default video input type.
  static DiveInputType get video =>
      DiveInputType('b11c0e88-0726-4889-8853-d801dc6c2c22', 'Video');

  static DiveInputType? fromMap(Map<String, dynamic> map) {
    if (map['uuid'] == null || map['name'] == null) {
      return null;
    }
    return DiveInputType(map['uuid'], map['name']);
  }

  @override
  String toString() {
    return "DiveInputType name: $name, uuid: $uuid";
  }
}

/// The list of registered Dive input types, which include the default types.
class DiveInputTypes {
  static List<DiveInputType> defaultInputTypes() => [
        DiveInputType.audio,
        DiveInputType.image,
        DiveInputType.media,
        DiveInputType.text,
        DiveInputType.video
      ];

  /// The list of registered Dive input types.
  static List<DiveInputType> get all => _all;

  /// The internal list of registered Dive input types
  static final List<DiveInputType> _all = defaultInputTypes();

  /// Registers a new Dive input type.
  static bool registerNewInputType(DiveInputType newType) {
    final any = _all
        .any((type) => newType.name == type.name || newType.uuid == type.uuid);
    if (any) {
      return false;
    }
    _all.add(newType);
    return true;
  }
}
