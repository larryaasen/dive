class _DiveInput {
  _DiveInput();
}

class DiveVideoInput extends _DiveInput {
  final String name;
  final String id;

  DiveVideoInput({this.name, this.id});

  static DiveVideoInput fromJson(dynamic json) {
    return DiveVideoInput(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return "DiveVideoInput name: $name, id: $id";
  }
}
