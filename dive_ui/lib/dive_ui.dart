library dive_ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:dive_core/dive_core.dart';

/// A widget showing a preview of a video/image frame using a [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview(this.controller);

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    final texture = controller != null && controller.value.isInitialized
        ? Texture(textureId: controller.textureId)
        : Container(color: Colors.blue);

    return texture;
  }
}
