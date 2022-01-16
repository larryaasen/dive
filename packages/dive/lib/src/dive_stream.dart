/// A [Stream] that produces [DiveDataStreamItem] events.
typedef DiveStream = Stream<DiveDataStreamItem>;

enum DiveSourceOutputType {
  audio,
  drawing,
  frame,
  text,
}

class DiveSourceOutputConfiguration {}

/// This object is sent to every downstream process of the source. It is sent
/// as one item in the stream.
class DiveDataStreamItem {
  final dynamic data;
  // TODO: make this non-optional
  final DiveSourceOutputType? type;
  // TODO: make this non-optional
  final DiveSourceOutputConfiguration? configuration;

  DiveDataStreamItem({this.data, this.type, this.configuration});
}
