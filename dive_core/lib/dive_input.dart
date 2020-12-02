class DiveInput {
  final String name;
  final String id;
  DiveInput({this.name, this.id});
}

class DiveVideoInput extends DiveInput {
  DiveVideoInput({String name, String sourceId})
      : super(name: name, id: sourceId);

  static DiveVideoInput fromJson(dynamic json) {
    return DiveVideoInput(
      sourceId: json['id'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return "DiveVideoInput name: $name, id: $id";
  }
}
