import 'package:dive/dive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget to display a multi-channel audio meter. It can be displayed
/// either horizonally or verically (default).
class DiveAudioMeter extends ConsumerWidget {
  const DiveAudioMeter({Key key, @required this.volumeMeter, this.vertical = true}) : super(key: key);

  final DiveAudioMeterSource volumeMeter;
  final bool vertical;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (volumeMeter == null) {
      return Container();
    }

    final stateModel = watch(volumeMeter.stateProvider.state);
    final painter = DiveAudioMeterPainter(state: stateModel, vertical: vertical);
    final paint = CustomPaint(foregroundPainter: painter);
    return paint;
  }
}

// DateTime lastUpdateTime;

class DiveAudioMeterPainter extends CustomPainter {
  final DiveAudioMeterState state;
  final bool vertical;

  final gap = 2;
  final thickness = 4;
  final margin = 2;

  DiveAudioMeterPainter({this.state, this.vertical = true});

  @override
  void paint(Canvas canvas, Size size) {
    // print("paint: $size, channelCount=${state.channelCount}, vert=$vertical");

    for (var channelIndex = 0; channelIndex < state.channelCount; channelIndex++) {
      if (vertical) {
        try {
          paintVertical(
            canvas,
            margin + (channelIndex * (thickness + gap)),
            margin,
            thickness,
            size.height.round() - (margin * 2) + 1,
            state.magnitudeAttacked[channelIndex],
            state.peakDecayed[channelIndex],
            state.peakHold[channelIndex],
            state.noSignal,
          );
        } catch (e, s) {
          print("DiveAudioMeterPainter.paintVertical exception: $e\n$s");
        }
      } else {
        int y = size.height.round() - margin - thickness;
        y -= ((state.channelCount - channelIndex - 1) * (thickness + gap));
        try {
          paintHorizontal(
            canvas,
            margin,
            y,
            size.width.round() - (margin * 2),
            thickness,
            state.magnitudeAttacked[channelIndex],
            state.peakDecayed[channelIndex],
            state.peakHold[channelIndex],
            state.inputPeakHold[channelIndex],
            state.noSignal,
          );
        } catch (e, s) {
          print("DiveAudioMeterPainter.paintHorizontal exception: $e\n$s");
        }
      }
    }
  }

  // Levels in dB
  final errorLevel = -9.0;
  final warningLevel = -20.0;
  final minimumLevel = DiveAudioMeterSource.audioMinLevel;
  final minimumInputLevel = -50.0;
  final clipLevel = -0.5;

  final backgroundColor = Color.fromARGB(0xff, 0x26, 0x7f, 0x26);
  final backgroundWarningColor = Color.fromARGB(0xff, 0x7f, 0x7f, 0x26);
  final backgroundErrorColor = Color.fromARGB(0xff, 0x7f, 0x26, 0x26);

  final foregroundColor = Color.fromARGB(0xff, 0x4c, 0xff, 0x4c);
  final foregroundWarningColor = Color.fromARGB(0xff, 0xff, 0xff, 0x4c);
  final foregroundErrorColor = Color.fromARGB(0xff, 0xff, 0x4c, 0x4c);

  final clipColor = Color.fromARGB(0xff, 0xff, 0xff, 0xff);
  final magnitudeColor = Color.fromARGB(0xff, 0x00, 0x00, 0x00);

  final miniBox = 3;

  bool clipping = false;
  int positionOffset;

  void fillRect(Canvas canvas, Color color, int left, int top, int width, int height) {
    try {
      top = positionOffset == null ? top : positionOffset - top;
      height = positionOffset == null ? height : positionOffset - height;
      final rect = Rect.fromLTWH(left.toDouble(), top.toDouble(), width.toDouble(), height.toDouble());
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);
    } catch (e) {
      print("DiveAudioMeterPainter.fillRect exception: $e");
    }
  }

  void paintHorizontal(
    Canvas canvas,
    int x,
    int y,
    int width,
    int height,
    double magnitude,
    double peak,
    double peakHold,
    double inputPeakHold,
    bool noSignal,
  ) {
    final scale = width / minimumLevel;

    peak = noSignal ? minimumLevel : peak;

    int minimumPosition = x + 0;
    int maximumPosition = x + width;
    int magnitudePosition = (maximumPosition - (magnitude * scale)).floor();
    int peakPosition = (maximumPosition - (peak * scale)).floor();

    // print(
    //     "maximumPosition=$maximumPosition, peak=$peak, peakHold=$peakHold, scale=$scale");
    int peakHoldPosition = (maximumPosition - (peakHold * scale)).floor();

    int warningPosition = (maximumPosition - (warningLevel * scale)).floor();
    int errorPosition = (maximumPosition - (errorLevel * scale)).floor();

    int nominalLength = warningPosition - minimumPosition;
    int warningLength = errorPosition - warningPosition;
    int errorLength = maximumPosition - errorPosition;

    if (clipping) {
      peakPosition = maximumPosition;
    }

    if (peakPosition <= minimumPosition) {
      fillRect(canvas, backgroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, backgroundWarningColor, warningPosition, y, warningLength, height);
      fillRect(canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < warningPosition) {
      fillRect(canvas, foregroundColor, minimumPosition, y, peakPosition - minimumPosition, height);
      fillRect(canvas, backgroundColor, peakPosition, y, warningPosition - peakPosition, height);
      fillRect(canvas, backgroundWarningColor, warningPosition, y, warningLength, height);
      fillRect(canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < errorPosition) {
      fillRect(canvas, foregroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, foregroundWarningColor, warningPosition, y, peakPosition - warningPosition, height);
      fillRect(canvas, backgroundWarningColor, peakPosition, y, errorPosition - peakPosition, height);
      fillRect(canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < maximumPosition) {
      fillRect(canvas, foregroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, foregroundWarningColor, warningPosition, y, warningLength, height);
      fillRect(canvas, foregroundErrorColor, errorPosition, y, peakPosition - errorPosition, height);
      fillRect(canvas, backgroundErrorColor, peakPosition, y, maximumPosition - peakPosition, height);
    } else if (magnitude != 0.0) {
      if (!clipping) {
        clipping = true;
      }

      int end = errorLength + warningLength + nominalLength;
      fillRect(canvas, foregroundErrorColor, minimumPosition, y, end, height);
    }

    if (noSignal) return;

    // Mini peak box
    if (peakHoldPosition - miniBox < minimumPosition) {
    } else if (peakHoldPosition < warningPosition) {
      fillRect(canvas, foregroundColor, peakHoldPosition - miniBox, y, miniBox, height);
    } else if (peakHoldPosition < errorPosition) {
      fillRect(canvas, foregroundWarningColor, peakHoldPosition - miniBox, y, miniBox, height);
    } else {
      fillRect(canvas, foregroundErrorColor, peakHoldPosition - miniBox, y, miniBox, height);
    }

    // Mini trailing box
    if (magnitudePosition - miniBox >= minimumPosition)
      fillRect(canvas, magnitudeColor, magnitudePosition - miniBox, y, miniBox, height);

    //   // summary box
    //   Color peakColor;
    //   if (inputPeakHold < minimumInputLevel)
    //     peakColor = backgroundColor;
    //   else if (inputPeakHold < warningLevel)
    //     peakColor = foregroundColor;
    //   else if (inputPeakHold < errorLevel)
    //     peakColor = foregroundWarningColor;
    //   else if (inputPeakHold <= clipLevel)
    //     peakColor = foregroundErrorColor;
    //   else
    //     peakColor = clipColor;

    //   fillRect(canvas, peakColor, 0, y, miniBox, height);
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
      fillRect(canvas, backgroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width, warningLength);
      fillRect(canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > warningPosition) {
      fillRect(canvas, foregroundColor, x, peakPosition, width, minimumPosition - peakPosition);

      fillRect(canvas, backgroundColor, x, warningPosition, width, peakPosition - warningPosition);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width, warningLength);
      fillRect(canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > errorPosition) {
      fillRect(canvas, foregroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, foregroundWarningColor, x, peakPosition, width, warningPosition - peakPosition);
      fillRect(canvas, backgroundWarningColor, x, errorPosition, width, peakPosition - errorPosition);
      fillRect(canvas, backgroundErrorColor, x, maximumPosition, width, errorLength);
    } else if (peakPosition > maximumPosition) {
      fillRect(canvas, foregroundColor, x, warningPosition, width, nominalLength);
      fillRect(canvas, foregroundWarningColor, x, errorPosition, width, warningLength);
      fillRect(canvas, foregroundErrorColor, x, peakPosition, width, errorPosition - peakPosition);
      fillRect(canvas, backgroundErrorColor, x, maximumPosition, width, peakPosition - maximumPosition);
    } else {
      if (!clipping) {
        clipping = true;
      }

      int end = errorLength + warningLength + nominalLength;
      fillRect(canvas, foregroundErrorColor, x, maximumPosition, width, end);
    }

    if (noSignal) return;

    // Mini box
    if (peakHoldPosition + miniBox > minimumPosition) {
    } else if (peakHoldPosition > warningPosition)
      fillRect(canvas, foregroundColor, x, peakHoldPosition + miniBox, width, miniBox);
    else if (peakHoldPosition > errorPosition)
      fillRect(canvas, foregroundWarningColor, x, peakHoldPosition + miniBox, width, miniBox);
    else
      fillRect(canvas, foregroundErrorColor, x, peakHoldPosition + miniBox, width, miniBox);

    if (magnitudePosition + miniBox < minimumPosition)
      fillRect(canvas, magnitudeColor, x, magnitudePosition + miniBox, width, miniBox);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}
