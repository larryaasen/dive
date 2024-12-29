// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dive_core/dive_core.dart';
import 'package:flutter/widgets.dart';

/// A widget to display a multi-channel audio meter. It can be displayed
/// either horizonally or verically (default).
/// The meter bar is displayed in color segments. Where there is no signal,
/// the segments are dark green, dark yellow, and dark red.
/// The yellow segment is the warning segment.
/// The red segment is the error segment.
class DiveAudioMeter extends StatelessWidget {
  /// Creates a widget to display a multi-channel audio meter.
  const DiveAudioMeter({
    super.key,
    required this.values,
    this.vertical = true,
    this.gap = 1,
    this.thickness = 7,
    this.gapColor,
    this.showLabels = true,
    this.labelThickness = 1,
  });

  /// The input values for the audio meter.
  final DiveAudioMeterValues values;

  /// Whether the meter is displayed vertically (default) or horizontally.
  final bool vertical;

  /// The gap between the meter bars when channel count > 1. Defaults to 2.
  final int gap;

  /// The thickness of the meter bars. Defaults to 4.
  final int thickness;

  /// The color of the gap between the meter bars when channel count > 1. Defaults to transparent.
  final Color? gapColor;

  /// Whether to show the labels. Defaults to false.
  final bool showLabels;

  /// The thickness of the label. Defaults to 1.
  final int labelThickness;

  @override
  Widget build(BuildContext context) {
    final painter = _DiveAudioMeterPainter(
      input: values,
      vertical: vertical,
      gap: gap,
      thickness: thickness,
      showLabels: showLabels,
      labelThickness: labelThickness,
    );
    return Container(
      width: width(),
      height: height(),
      color: gapColor,
      child: CustomPaint(foregroundPainter: painter),
    );
  }

  double height() {
    return vertical
        ? double.infinity
        : values.channelCount == 0
            ? 0
            : ((values.channelCount * thickness) +
                    ((values.channelCount - 1) * gap))
                .toDouble();
  }

  double width() {
    return vertical
        ? values.channelCount == 0
            ? 0
            : ((values.channelCount * thickness) +
                    ((values.channelCount - 1) * gap))
                .toDouble()
        : double.infinity;
  }
}

// DateTime lastUpdateTime;

class _DiveAudioMeterPainter extends CustomPainter {
  _DiveAudioMeterPainter({
    required this.input,
    required this.vertical,
    required this.gap,
    required this.thickness,
    required this.showLabels,
    required this.labelThickness,
  });

  final DiveAudioMeterValues input;
  final bool vertical;
  final int gap;
  final int thickness;
  final bool showLabels;
  final int labelThickness;

  @override
  void paint(Canvas canvas, Size size) {
    for (var channelIndex = 0;
        channelIndex < input.channelCount;
        channelIndex++) {
      // Get the data values from the input.
      final magnitude = channelIndex < input.magnitude.length
          ? input.magnitude[channelIndex]
          : DiveAudioMeterConst.minLevel;
      final peak = channelIndex < input.peak.length
          ? input.peak[channelIndex]
          : DiveAudioMeterConst.minLevel;
      final peakHold = channelIndex < input.peakHold.length
          ? input.peakHold[channelIndex]
          : DiveAudioMeterConst.minLevel;

      if (vertical) {
        // Vertical
        int x = channelIndex * (thickness + gap);
        int y = 0;
        try {
          paintVertical(
            canvas: canvas,
            x: x,
            y: y,
            width: thickness,
            height: size.height.round() + 1,
            magnitude: magnitude,
            peak: peak,
            peakHold: peakHold,
            noSignal: input.noSignal,
          );
        } catch (e, s) {
          print("DiveAudioMeterPainter.paintVertical exception: $e\n$s");
        }
      } else {
        // Horizontal
        int x = 0;
        int y = channelIndex * (thickness + gap);
        // y -= ((input.channelCount - channelIndex - 1) * (thickness + gap));
        int width = size.width.round();
        int height = thickness;
        try {
          paintHorizontal(
            canvas: canvas,
            x: x,
            y: y,
            width: width,
            height: height,
            magnitude: magnitude,
            peak: peak,
            peakHold: peakHold,
            noSignal: input.noSignal,
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
  final minimumLevel = DiveAudioMeterConst.minLevel;
  // final minimumInputLevel = -50.0;
  final clipLevel = -0.5;

  final backgroundColor = const Color.fromARGB(0xff, 0x26, 0x7f, 0x26);
  final backgroundWarningColor = const Color.fromARGB(0xff, 0x7f, 0x7f, 0x26);
  final backgroundErrorColor = const Color.fromARGB(0xff, 0x7f, 0x26, 0x26);

  final foregroundColor = const Color.fromARGB(0xff, 0x4c, 0xff, 0x4c);
  final foregroundWarningColor = const Color.fromARGB(0xff, 0xff, 0xff, 0x4c);
  final foregroundErrorColor = const Color.fromARGB(0xff, 0xff, 0x4c, 0x4c);

  final clipColor = const Color.fromARGB(0xff, 0xff, 0xff, 0xff);
  final magnitudeColor = const Color.fromARGB(0xff, 0x00, 0x00, 0x00);

  final miniBox = 3;
  bool clipping = false;

  final int tickLength = 2;
  final int tickThickness = 1;
  final tickColor = const Color.fromARGB(0xff, 0xff, 0xff, 0xff);

  void fillRect(
      Canvas canvas, Color color, int left, int top, int width, int height) {
    try {
      final rect = Rect.fromLTWH(
          left.toDouble(), top.toDouble(), width.toDouble(), height.toDouble());
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);
    } catch (e) {
      print("DiveAudioMeterPainter.fillRect exception: $e");
    }
  }

  void paintHorizontal({
    required Canvas canvas,
    required int x,
    required int y,
    required int width,
    required int height,
    required double magnitude,
    required double peak,
    required double peakHold,
    // required double inputPeakHold,
    required bool noSignal,
  }) {
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
      fillRect(
          canvas, backgroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, backgroundWarningColor, warningPosition, y,
          warningLength, height);
      fillRect(
          canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < warningPosition) {
      fillRect(canvas, foregroundColor, minimumPosition, y,
          peakPosition - minimumPosition, height);
      fillRect(canvas, backgroundColor, peakPosition, y,
          warningPosition - peakPosition, height);
      fillRect(canvas, backgroundWarningColor, warningPosition, y,
          warningLength, height);
      fillRect(
          canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < errorPosition) {
      fillRect(
          canvas, foregroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, foregroundWarningColor, warningPosition, y,
          peakPosition - warningPosition, height);
      fillRect(canvas, backgroundWarningColor, peakPosition, y,
          errorPosition - peakPosition, height);
      fillRect(
          canvas, backgroundErrorColor, errorPosition, y, errorLength, height);
    } else if (peakPosition < maximumPosition) {
      fillRect(
          canvas, foregroundColor, minimumPosition, y, nominalLength, height);
      fillRect(canvas, foregroundWarningColor, warningPosition, y,
          warningLength, height);
      fillRect(canvas, foregroundErrorColor, errorPosition, y,
          peakPosition - errorPosition, height);
      fillRect(canvas, backgroundErrorColor, peakPosition, y,
          maximumPosition - peakPosition, height);
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
      fillRect(canvas, foregroundColor, peakHoldPosition - miniBox, y, miniBox,
          height);
    } else if (peakHoldPosition < errorPosition) {
      fillRect(canvas, foregroundWarningColor, peakHoldPosition - miniBox, y,
          miniBox, height);
    } else {
      fillRect(canvas, foregroundErrorColor, peakHoldPosition - miniBox, y,
          miniBox, height);
    }

    // Mini trailing box
    if (magnitudePosition - miniBox >= minimumPosition) {
      fillRect(canvas, magnitudeColor, magnitudePosition - miniBox, y, miniBox,
          height);
    }

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

    if (false) {
      //(showLabels) {
      // Draw tick marks and text labels
      for (int i = 0; i >= minimumLevel; i -= 5) {
        int position = (x + width - (i * scale) - 1).toInt();
        final str = i.toString();

        // Center the number on the tick, but don't overflow
        const textBounds = Size(10, 20);
        int pos;
        if (i == 0) {
          pos = position - textBounds.width.toInt();
        } else {
          pos = position - (textBounds.width / 2).toInt();
          if (pos < 0) pos = 0;
        }
        // painter.drawText(pos, y + 4 + metrics.capHeight(), str);

        fillRect(canvas, tickColor, position, y, position, y + 2);
      }
    }
  }

  void paintVertical({
    required Canvas canvas,
    required int x,
    required int y,
    required int width,
    required int height,
    required double magnitude,
    required double peak,
    required double peakHold,
    required bool noSignal,
  }) {
    final scale = height / minimumLevel;

    final usePeak = noSignal ? minimumLevel : peak;

    int minimumPosition = y + height;
    int maximumPosition = y + 0;
    int magnitudePosition = (maximumPosition + (magnitude * scale)).floor();
    int peakPosition = (maximumPosition + (usePeak * scale)).floor();
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
        clipping = true;
      }

      int end = errorLength + warningLength + nominalLength;
      fillRect(canvas, foregroundErrorColor, x, maximumPosition, width, end);
    }

    if (noSignal) return;

    // Mini box
    if (peakHoldPosition + miniBox > minimumPosition) {
    } else if (peakHoldPosition > warningPosition) {
      fillRect(canvas, foregroundColor, x, peakHoldPosition + miniBox, width,
          miniBox);
    } else if (peakHoldPosition > errorPosition) {
      fillRect(canvas, foregroundWarningColor, x, peakHoldPosition + miniBox,
          width, miniBox);
    } else {
      fillRect(canvas, foregroundErrorColor, x, peakHoldPosition + miniBox,
          width, miniBox);
    }

    if (magnitudePosition + miniBox < minimumPosition) {
      fillRect(canvas, magnitudeColor, x, magnitudePosition + miniBox, width,
          miniBox);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class DiveAudioMeterStream {
  late StreamController<DiveAudioMeterValues> _valuesController;

  DiveAudioMeterStream() {
    _valuesController = StreamController<DiveAudioMeterValues>(onCancel: stop);
  }

  Stream<DiveAudioMeterValues> get stream => _valuesController.stream;

  void audioMeterCallback(String deviceUniqueID, List<double> magnitude,
      List<double> peak, List<double> inputPeak) {
    // print('magnitude: $magnitude, peak: $peak, inputPeak: $inputPeak');

    final values = DiveAudioMeterValues(
        channelCount: magnitude.length,
        magnitude: magnitude,
        peak: peak,
        peakHold: inputPeak,
        noSignal: false);

    // Send the values to the stream.
    _valuesController.add(values);
  }

  // Stops the audio simulation
  void stop() {
    _valuesController.close();
  }
}
