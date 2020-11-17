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
