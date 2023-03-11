import 'package:dive_obslib/dive_obslib.dart';

/// An input type, such as display_capture or image_source.
class DiveInputType {
  final String? id;
  final String? name;

  DiveInputType({this.id, this.name});

  static DiveInputType get audioSource => DiveInputType(id: 'coreaudio_input_capture', name: 'Audio Source');
  static DiveInputType get displayCapture => DiveInputType(id: 'display_capture', name: 'Display Capture');
  static DiveInputType get imageSource => DiveInputType(id: 'image_source', name: 'Image Source');
  static DiveInputType get mediaSource => DiveInputType(id: 'ffmpeg_source', name: 'Media Source');
  static DiveInputType get videoCaptureDevice =>
      DiveInputType(id: 'av_capture_input', name: 'Video Capture Device');

  /// All available input types.
  static Future<List<DiveInputType>> all({sortedByName = true}) async {
    var list = obslib.inputTypes.map(DiveInputType.fromJson).toList();
    if (sortedByName) {
      list.sort(((a, b) => a.name!.compareTo(b.name!)));
    }
    return list;
  }

  static DiveInputType fromJson(dynamic json) => DiveInputType(id: json['id'], name: json['name']);

  @override
  String toString() => "DiveInputType id: $id, name: $name";
}
