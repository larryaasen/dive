import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as imglib;

/// A frame of video.
class DiveFrame {
  /// The frame bytes.
  final Uint8List bytes;

  /// The frame width.
  final int width;

  /// The frame height.
  final int height;

  /// Creates a [MemoryImage] from the [frame] bytes.
  MemoryImage get memoryImage => MemoryImage(bytes);

  /// Creates a [DiveFrame].
  DiveFrame({required this.bytes, required this.width, required this.height});

  /// Creates a [DiveFrame] from image bytes.
  factory DiveFrame.fromBytes(Uint8List bytes) {
    // Decode the image just to determine the width and height.
    final image = imglib.decodeImage(bytes);
    if (image != null) {
      return DiveFrame(bytes: bytes, width: image.width, height: image.height);
    }
    throw ArgumentError('bytes does not contain a valid image.', 'bytes');
  }
}

/// Add support for [imglib.Image] operations.
extension DiveFrameImage on DiveFrame {
  /// Creates an [imglib.Image] from the frame bytes.
  imglib.Image get image {
    // Decode the image just to determine the width and height.
    final image = imglib.decodeImage(bytes);
    if (image != null) {
      return image;
    }
    throw ArgumentError('bytes does not contain a valid image.', 'bytes');
  }
}

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
  /// A frame of video. Used only when [type] is [DiveSourceOutputType.frame].
  final DiveFrame? frame;

  // TODO: make this non-optional
  final DiveSourceOutputType type;

  // TODO: make this non-optional
  final DiveSourceOutputConfiguration? configuration;

  DiveDataStreamItem(
      {this.frame, this.type = DiveSourceOutputType.frame, this.configuration});
}
