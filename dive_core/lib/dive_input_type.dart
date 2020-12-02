class DiveInputType {
  final String id;
  final String name;

  DiveInputType({this.id, this.name});

  static DiveInputType videoCaptureDevice() =>
      DiveInputType(id: 'av_capture_input', name: 'Video Capture Device');

  static DiveInputType fromJson(dynamic json) {
    return DiveInputType(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return "DiveInputType name: $name, id: $id";
  }
}
