import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as imglib;

/// A frame of video.
class DiveFrame {
  /// The frame bytes.
  final Uint8List bytes;

  final ui.Image? uiImage;

  /// The frame width.
  final int width;

  /// The frame height.
  final int height;

  final MemoryImage _cacheImage;

  /// Creates a [MemoryImage] from the [frame] bytes.
  MemoryImage get memoryImage => _cacheImage;

  /// Creates a [DiveFrame].
  DiveFrame(
      {required this.bytes,
      required this.width,
      required this.height,
      this.uiImage})
      : _cacheImage = MemoryImage(bytes);

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
    // Decode the image
    final image = imglib.decodeImage(bytes);
    if (image != null) {
      return image;
    }
    throw ArgumentError('bytes does not contain a valid image.', 'bytes');
  }

  Future<ui.Image?> get uiImageLive async {
    try {
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor =
          await ui.ImageDescriptor.encoded(buffer);

      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      return null;
    }
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

  final String? text;

  // TODO: make this non-optional
  final DiveSourceOutputType type;

  // TODO: make this non-optional
  final DiveSourceOutputConfiguration? configuration;

  DiveDataStreamItem(
      {this.frame,
      this.text,
      this.type = DiveSourceOutputType.frame,
      this.configuration});
}
