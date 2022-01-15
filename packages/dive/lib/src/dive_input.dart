import 'dive_input_type.dart';
import 'dive_sources.dart';

/// Represents one specific input, such as FaceTime camera or main microphone.
class DiveInput {
  /// The input name, such as `FaceTime HD Camera (Built-in)`.
  final String name;

  /// The input id, such as `0x8020000005ac8514`.
  final String id;

  /// The input type, such as `image_source` or `av_capture_input`.
  final DiveInputType type;

  const DiveInput({required this.name, required this.id, required this.type});

  static DiveInput? fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['name'] == null || map['type'] == null) {
      return null;
    }
    return DiveInput(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }

  @override
  String toString() {
    return "DiveInput name: $name, id: $id, type: $type";
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
