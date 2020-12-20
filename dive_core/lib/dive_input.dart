class _DiveInput {
  _DiveInput();
}

class DiveVideoInput extends _DiveInput {
  final String name;
  final String id;

  DiveVideoInput({this.name, this.id});

  static DiveVideoInput fromMap(dynamic map) {
    return DiveVideoInput(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  String toString() {
    return "DiveVideoInput name: $name, id: $id";
  }
}
