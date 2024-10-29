// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: prefer_const_constructors

import 'package:dive_core/dive_core.dart';
import 'package:dive_widgets/src/dive_audio_meter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DiveAudioMeterInput', () {
    expect(const DiveAudioMeterValues(channelCount: 0).channelCount, 0);
    expect(const DiveAudioMeterValues(channelCount: 1).channelCount, 1);
    expect(const DiveAudioMeterValues(channelCount: 2).channelCount, 2);
    expect(const DiveAudioMeterValues(channelCount: 3).channelCount, 3);
    expect(const DiveAudioMeterValues(channelCount: 4).channelCount, 4);
    expect(const DiveAudioMeterValues(channelCount: 5).channelCount, 5);
    expect(const DiveAudioMeterValues(channelCount: 6).channelCount, 6);
    expect(const DiveAudioMeterValues(channelCount: 7).channelCount, 7);
    expect(const DiveAudioMeterValues(channelCount: 8).channelCount, 8);
  });

  test('DiveAudioMeter sizes', () {
    expect(
        DiveAudioMeter(values: DiveAudioMeterValues(channelCount: 0)).width(),
        0);
    expect(
        DiveAudioMeter(values: DiveAudioMeterValues(channelCount: 1)).width(),
        4);
    expect(
        DiveAudioMeter(values: DiveAudioMeterValues(channelCount: 2)).width(),
        10);
    expect(
        DiveAudioMeter(values: DiveAudioMeterValues(channelCount: 4)).width(),
        22);
    expect(
        DiveAudioMeter(values: DiveAudioMeterValues(channelCount: 4)).height(),
        double.infinity);

    expect(
        DiveAudioMeter(
                values: DiveAudioMeterValues(channelCount: 0), vertical: false)
            .height(),
        0);
    expect(
        DiveAudioMeter(
                values: DiveAudioMeterValues(channelCount: 1), vertical: false)
            .height(),
        4);
    expect(
        DiveAudioMeter(
                values: DiveAudioMeterValues(channelCount: 2), vertical: false)
            .height(),
        10);
    expect(
        DiveAudioMeter(
                values: DiveAudioMeterValues(channelCount: 4), vertical: false)
            .height(),
        22);
    expect(
        DiveAudioMeter(
                values: DiveAudioMeterValues(channelCount: 4), vertical: false)
            .width(),
        double.infinity);
  });

  testWidgets('DiveAudioMeterPaint vertical one channel',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(values: DiveAudioMeterValues())))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile('golden/dive_widgets.DiveAudioMeterPaint.1V.png'),
    );
  });

  testWidgets('DiveAudioMeterPaint vertical two channel',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(values: DiveAudioMeterValues())))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile('golden/dive_widgets.DiveAudioMeterPaint.2V.png'),
    );
  });

  testWidgets('DiveAudioMeterPaint horizontal one channel',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(
          values: DiveAudioMeterValues(),
          vertical: false,
        )))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile('golden/dive_widgets.DiveAudioMeterPaint.1H.png'),
    );
  });

  testWidgets('DiveAudioMeterPaint horizontal two channel',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(
          values: DiveAudioMeterValues(),
          vertical: false,
        )))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile('golden/dive_widgets.DiveAudioMeterPaint.2H.png'),
    );
  });

  testWidgets('DiveAudioMeterPaint noSignal', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(
          values: DiveAudioMeterValues(),
          vertical: false,
        )))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile(
          'golden/dive_widgets.DiveAudioMeterPaint.noSignal.2H.png'),
    );

    await tester.pumpWidget(wrap(const SizedBox(
        width: 500,
        height: 500,
        child: RepaintBoundary(
            child: DiveAudioMeter(
          values: DiveAudioMeterValues(),
          vertical: true,
        )))));
    await expectLater(
      find.byType(DiveAudioMeter),
      matchesGoldenFile(
          'golden/dive_widgets.DiveAudioMeterPaint.noSignal.2V.png'),
    );
  });
}

Widget wrap(Widget child) {
  // Using Center for some reason makes the output image size 500x500, instead
  // of 800x600, which is smaller.
  return Center(child: child);
}
