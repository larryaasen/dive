import 'package:dive/dive.dart';
import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configDiveApp();
  });

  tearDown(() {});

  testWidgets('DiveAudioMeterPaint vertical', (WidgetTester tester) async {
    final state = DiveAudioMeterState(
        channelCount: 2,
        inputPeak: [-32.2206916809082, -34.92798614501953],
        inputPeakHold: [-19.778120040893555, -22.0262508392334],
        magnitude: [-40.155426025390625, -42.87294006347656],
        magnitudeAttacked: [-38.39295041595973, -40.50778031717143],
        peak: [-32.2206916809082, -34.92798614501953],
        peakDecayed: [-22.771781382841212, -24.99095672158633],
        peakHold: [-19.778120040893555, -22.0262508392334],
        inputpPeakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        peakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        lastUpdateTime: DateTime.parse("2022-04-05 08:20:09.527938"),
        noSignal: false);

    await tester
        .pumpWidget(wrap(SizedBox(width: 500, height: 500, child: DiveAudioMeterPaint(state: state))));
    await expectLater(
      find.byType(DiveAudioMeterPaint),
      matchesGoldenFile('golden/DiveAudioMeterPaint-V.png'),
    );
  });
  testWidgets('DiveAudioMeterPaint horizontal', (WidgetTester tester) async {
    final state = DiveAudioMeterState(
        channelCount: 2,
        inputPeak: [-32.2206916809082, -34.92798614501953],
        inputPeakHold: [-19.778120040893555, -22.0262508392334],
        magnitude: [-40.155426025390625, -42.87294006347656],
        magnitudeAttacked: [-38.39295041595973, -40.50778031717143],
        peak: [-32.2206916809082, -34.92798614501953],
        peakDecayed: [-22.771781382841212, -24.99095672158633],
        peakHold: [-19.778120040893555, -22.0262508392334],
        inputpPeakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        peakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        lastUpdateTime: DateTime.parse("2022-04-05 08:20:09.527938"),
        noSignal: false);

    await tester.pumpWidget(wrap(SizedBox(
        width: 500,
        height: 500,
        child: DiveAudioMeterPaint(
          state: state,
          vertical: false,
        ))));
    await expectLater(
      find.byType(DiveAudioMeterPaint),
      matchesGoldenFile('golden/DiveAudioMeterPaint-H.png'),
    );
  });
  testWidgets('DiveAudioMeterPaint noSignal', (WidgetTester tester) async {
    final state = DiveAudioMeterState(
        channelCount: 2,
        inputPeak: [-32.2206916809082, -34.92798614501953],
        inputPeakHold: [-19.778120040893555, -22.0262508392334],
        magnitude: [-40.155426025390625, -42.87294006347656],
        magnitudeAttacked: [-38.39295041595973, -40.50778031717143],
        peak: [-32.2206916809082, -34.92798614501953],
        peakDecayed: [-22.771781382841212, -24.99095672158633],
        peakHold: [-19.778120040893555, -22.0262508392334],
        inputpPeakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        peakHoldLastUpdateTime: [
          DateTime.parse("2022-04-05 08:20:09.047773"),
          DateTime.parse("2022-04-05 08:20:09.271743")
        ],
        lastUpdateTime: DateTime.parse("2022-04-05 08:20:09.527938"),
        noSignal: true);

    await tester.pumpWidget(wrap(SizedBox(
        width: 500,
        height: 500,
        child: DiveAudioMeterPaint(
          state: state,
          vertical: false,
        ))));
    await expectLater(
      find.byType(DiveAudioMeterPaint),
      matchesGoldenFile('golden/DiveAudioMeterPaint-noSignal.png'),
    );
  });

  testWidgets('DiveImagePickerButton', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(ProviderScope(child: DiveImagePickerButton())));
    await expectLater(
      find.byType(DiveImagePickerButton),
      matchesGoldenFile('golden/DiveImagePickerButton.png'),
    );
  });

  test('Verify DiveReferencePanelsCubit', () {
    final panelsCubit = DiveReferencePanelsCubit();

    // Verify initial state
    expect(panelsCubit.state.panels!.length, DiveReferencePanels.maxPanelSources);
    expect(panelsCubit.state.panels![2]!.assignedSource, isNull);

    // Verify assigning a new source
    final newSource = DiveVideoSource(name: 'camera1');
    panelsCubit.assignSource(newSource, panelsCubit.state.panels![2]);

    // We don't want the length to change
    expect(panelsCubit.state.panels!.length, DiveReferencePanels.maxPanelSources);
    // Verify assigned source was updated
    expect(panelsCubit.state.panels![2]!.assignedSource.runtimeType, newSource.runtimeType);
    expect(panelsCubit.state.panels![2]!.assignedSource!.name, 'camera1');

    // Verify assigning the same source
    panelsCubit.assignSource(newSource, panelsCubit.state.panels![2]);
    // Verify assigned source was the same
    expect(panelsCubit.state.panels![2]!.assignedSource.runtimeType, newSource.runtimeType);

    // Verify assigning null source
    panelsCubit.assignSource(null, panelsCubit.state.panels![2]);
    // Verify assigned source was nul
    expect(panelsCubit.state.panels![2]!.assignedSource, isNull);

    // At the end, close the cubit
    panelsCubit.close();
  });
}

Widget wrap(Widget child) {
  return FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(child: child),
      ),
    ),
  );
}
