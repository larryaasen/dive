import 'package:dive/dive.dart';
import 'package:flutter/widgets.dart';

import 'dive_ui.dart';

/// A [DivePreview] with a [DiveAudioMeter] overlay using a [DiveAudioMeterSource].
class DiveMeterPreview extends DivePreview {
  DiveMeterPreview({
    DiveTextureController? controller,
    required this.volumeMeter,
    Key? key,
    double? aspectRatio,
    this.meterVertical = false,
  }) : super(controller: controller, key: key, aspectRatio: aspectRatio);

  /// The volume meter to display over the preview.
  final DiveAudioMeterSource volumeMeter;

  /// Volume meter should be displayed vertically.
  final bool meterVertical;

  static const vPos = RelativeRect.fromLTRB(5, 5, 5, 5);
  static const hPos = RelativeRect.fromLTRB(5, 5, 5, 5);

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);

    final child = SizedBox.expand(
        child: DiveAudioMeter(
      volumeMeter: volumeMeter,
      vertical: meterVertical,
    ));

    final rect = meterVertical ? vPos : hPos;
    final meter = Positioned.fromRelativeRect(rect: rect, child: child);

    final stack = Stack(
      children: <Widget>[
        superWidget,
        meter,
      ],
    );

    return stack;
  }
}
