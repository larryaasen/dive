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

  testWidgets('DiveImagePickerButton', (WidgetTester tester) async {
    final elements = DiveCoreElements();
    await tester.pumpWidget(
        wrap(ProviderScope(child: DiveImagePickerButton(elements: elements))));
    await expectLater(
      find.byType(DiveImagePickerButton),
      matchesGoldenFile('golden/DiveImagePickerButton.png'),
    );
  });

  test('Verify DiveReferencePanelsCubit', () {
    final panelsCubit = DiveReferencePanelsCubit();

    // Verify initial state
    expect(
        panelsCubit.state.panels!.length, DiveReferencePanels.maxPanelSources);
    expect(panelsCubit.state.panels![2]!.assignedSource, isNull);

    // Verify assigning a new source
    final newSource = DiveVideoSource(name: 'camera1');
    panelsCubit.assignSource(newSource, panelsCubit.state.panels![2]);

    // We don't want the length to change
    expect(
        panelsCubit.state.panels!.length, DiveReferencePanels.maxPanelSources);
    // Verify assigned source was updated
    expect(panelsCubit.state.panels![2]!.assignedSource.runtimeType,
        newSource.runtimeType);
    expect(panelsCubit.state.panels![2]!.assignedSource!.name, 'camera1');

    // Verify assigning the same source
    panelsCubit.assignSource(newSource, panelsCubit.state.panels![2]);
    // Verify assigned source was the same
    expect(panelsCubit.state.panels![2]!.assignedSource.runtimeType,
        newSource.runtimeType);

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
