class DiveInputType {
  final String id;
  final String name;

  DiveInputType({this.id, this.name});

  static DiveInputType get audioSource =>
      DiveInputType(id: 'coreaudio_input_capture', name: 'Audio Source');

  static DiveInputType get imageSource =>
      DiveInputType(id: 'image_source', name: 'Image Source');

  static DiveInputType get mediaSource =>
      DiveInputType(id: 'ffmpeg_source', name: 'Media Source');

  static DiveInputType get videoCaptureDevice =>
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
