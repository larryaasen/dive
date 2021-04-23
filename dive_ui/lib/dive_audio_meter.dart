import 'package:dive_core/dive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiveAudioMeter extends ConsumerWidget {
  const DiveAudioMeter({Key key, @required this.volumeMeter}) : super(key: key);

  final DiveVolumeMeter volumeMeter;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (volumeMeter == null) {
      return Container();
    }

    final stateModel = watch(volumeMeter.stateProvider.state);
    final painter = DiveAudioMeterPainter(state: stateModel);
    final paint = CustomPaint(foregroundPainter: painter);
    return paint;
  }
}

DateTime lastUpdateTime;

class DiveAudioMeterPainter extends CustomPainter {
  final DiveVolumeMeterState state;
  final bool vertical;

  final gap = 2;
  final thickness = 4;
  final margin = 2;

  DiveAudioMeterPainter({this.state, this.vertical = true});

  @override
  void paint(Canvas canvas, Size size) {
    // print("paint: $size, channelCount=${state.channelCount}, vert=$vertical");

    for (var channelIndex = 0;
        channelIndex < state.channelCount;
        channelIndex++) {
      if (vertical) {
        final length = size.height.floor();

        try {
          paintVertical(
            canvas,
            channelIndex * (thickness + gap),
            margin,
            thickness,
            length - margin,
            state.magnitude[channelIndex],
            state.peak[channelIndex],
            state.inputPeak[channelIndex],
            state.noSignal,
          );
        } catch (e) {
          print("paintVertical exception: $e");
        }
      }
    }
  }

  // Levels in db
  final errorLevel = -9.0;
  final warningLevel = -20.0;
  final minimumLevel = -60.0;

  final backgroundColor = Color.fromARGB(0xff, 0x26, 0x7f, 0x26);
  final backgroundWarningColor = Color.fromARGB(0xff, 0x7f, 0x7f, 0x26);
  final backgroundErrorColor = Color.fromARGB(0xff, 0x7f, 0x26, 0x26);

  final foregroundColor = Color.fromARGB(0xff, 0x4c, 0xff, 0x4c);
  final foregroundWarningColor = Color.fromARGB(0xff, 0xff, 0xff, 0x4c);
  final foregroundErrorColor = Color.fromARGB(0xff, 0xff, 0x4c, 0x4c);

  final magnitudeColor = Color.fromARGB(0xff, 0x00, 0x00, 0x00);

  bool clipping = false;
  int positionOffset;

  void fillRect(
      Canvas canvas, Color color, int left, int top, int width, int height) {
    top = positionOffset == null ? top : positionOffset - top;
    height = positionOffset == null ? height : positionOffset - height;
    final rect = Rect.fromLTWH(
        left.toDouble(), top.toDouble(), width.toDouble(), height.toDouble());
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }

  void paintVertical(
    Canvas canvas,
    int x,
    int y,
    int width,
    int height,
    double magnitude,
    double peak,
    double peakHold,
    bool noSignal,
  ) {
    final scale = height / minimumLevel;

    peak = noSignal ? minimumLevel : peak;

    int minimumPosition = y + height;
    int maximumPosition = y + 0;
    int magnitudePosition = (maximumPosition + (magnitude * scale)).floor();
    int peakPosition = (maximumPosition + (peak * scale)).floor();
    int peakHoldPosition = (maximumPosition + (peakHold * scale)).floor();
    int warningPosition = (maximumPosition + (warningLevel * scale)).floor();
    int errorPosition = (maximumPosition + (errorLevel * scale)).floor();

    int nominalLength = minimumPosition - warningPosition;
    int warningLength = warningPosition - errorPosition;
    int errorLength = errorPosition - maximumPosition;

    if (clipping) {
      peakPosition = maximumPosition;
    }

    if (peakPosition >= minimumPosition) {
      fillRect(
          canvas, backgroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width,
          warningLength);
      fillRect(
          canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > warningPosition) {
      fillRect(canvas, foregroundColor, x, peakPosition, width,
          minimumPosition - peakPosition);

      fillRect(canvas, backgroundColor, x, warningPosition, width,
          peakPosition - warningPosition);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width,
          warningLength);
      fillRect(
          canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > errorPosition) {
      fillRect(
          canvas, foregroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, foregroundWarningColor, x, peakPosition, width,
          warningPosition - peakPosition);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width,
          peakPosition - errorPosition);
      fillRect(
          canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > maximumPosition) {
      fillRect(
          canvas, foregroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, foregroundWarningColor, x, errorPosition, width,
          warningLength);
      fillRect(canvas, foregroundErrorColor, x, peakPosition, width,
          errorPosition - peakPosition);
      fillRect(canvas, backgroundErrorColor, x, maximumPosition, width,
          peakPosition - maximumPosition);
    } else {
      if (!clipping) {
        // QTimer::singleShot(CLIP_FLASH_DURATION_MS, this,
        // 		   SLOT(ClipEnding()));
        clipping = true;
      }

      int end = errorLength + warningLength + nominalLength;
      fillRect(canvas, foregroundErrorColor, x, maximumPosition, width, end);
    }

    if (noSignal) return;

    if (peakHoldPosition + 3 > minimumPosition) {
    } else if (peakHoldPosition > warningPosition)
      fillRect(canvas, foregroundColor, x, peakHoldPosition + 3, width, 3);
    else if (peakHoldPosition > errorPosition)
      fillRect(
          canvas, foregroundWarningColor, x, peakHoldPosition + 3, width, 3);
    else
      fillRect(canvas, foregroundErrorColor, x, peakHoldPosition + 3, width, 3);

    if (magnitudePosition + 3 < minimumPosition)
      fillRect(canvas, magnitudeColor, x, magnitudePosition + 3, width, 3);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}
