// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:uvc/uvc.dart';

import 'checkbox_control.dart';
import 'slider_control.dart';

class CameraSettingsSection extends StatefulWidget {
  const CameraSettingsSection({super.key, required this.camera});

  final UvcControl camera;

  @override
  State<CameraSettingsSection> createState() => _CameraSettingsSectionState();
}

class _CameraSettingsSectionState extends State<CameraSettingsSection> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: Colors.black12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderControl(
              title: 'Brightness:', controller: widget.camera.brightness),
          SliderControl(title: 'Contrast:', controller: widget.camera.contrast),
          SliderControl(
              title: 'Saturation:', controller: widget.camera.saturation),
          SliderControl(
              title: 'Sharpness:', controller: widget.camera.sharpness),
          SliderControl(
              title: 'White Balance:', controller: widget.camera.whiteBalance),
          SliderControl(title: 'Pan:', controller: widget.camera.pan),
          SliderControl(title: 'Tilt:', controller: widget.camera.tilt),
          SliderControl(title: 'Zoom:', controller: widget.camera.zoom),
          SliderControl(
              titleWidget: CheckboxControl(
                  title: 'Auto:', controller: widget.camera.focusAuto),
              controller: widget.camera.focus),
        ],
      ),
    );
  }
}
