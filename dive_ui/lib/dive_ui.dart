library dive_ui;

import 'package:flutter/widgets.dart';
import 'package:dive_core/dive_core.dart';

// Build the UI texture view of the source data with textureId.
class SourceOutput extends StatelessWidget {
  const SourceOutput(this.controller);

  final SourceTextureController controller;

  @override
  Widget build(BuildContext context) {
    return controller.value == "ready"
        ? Texture(textureId: controller.textureId)
        : Container();
  }
}

/// A widget showing a texture.
class TexturePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const TexturePreview(this.controller);

  /// The controller for the texture that the preview is shown for.
  /// TODO: maybe this controller is not needed, and just use textureId.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    return controller != null && controller.value.isInitialized
        ? Texture(textureId: controller.textureId)
        : Container();
  }
}
