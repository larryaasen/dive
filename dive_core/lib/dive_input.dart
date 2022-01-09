import 'dive_sources.dart';

class DiveInput {
  /// The input name, such as `FaceTime HD Camera (Built-in)`.
  final String name;

  /// The input id, such as `0x8020000005ac8514`.
  final String id;

  /// The input type id, such as `image_source` or `av_capture_input`.
  /// TODO: Should eventually be changed to [DiveInputType].
  final String typeId;

  DiveInput({this.name, this.id, this.typeId});

  static DiveInput fromMap(dynamic map) {
    return DiveInput(
      id: map['id'],
      name: map['name'],
      typeId: map['type_id'],
    );
  }

  @override
  String toString() {
    return "DiveInput name: $name, id: $id, typeId: $typeId";
  }
}

class DiveInputs {
  static List<DiveInput> fromType(String typeId) =>
      DivePluginExt.inputsFromType(typeId);

  // TODO: Implement this audio() method.
  static List<DiveInput> audio() => [];

  // TODO: Implement this video() method.
  static List<DiveInput> video() => [];
}
