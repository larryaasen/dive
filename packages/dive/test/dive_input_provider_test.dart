// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dive/dive.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  tearDown(() {});
  test('DiveInputProviders all', () {
    expect(DiveInputProviders.all.length, 2);
    expect(DiveInputProviders.all[0].inputTypes()[0].uuid,
        DiveInputType.image.uuid);
    expect(DiveInputProviders.all[1].inputTypes()[0].uuid,
        DiveInputType.text.uuid);

    // Log the Dive input types: audio, text, video, etc.
    DiveInputProviders.all.forEach((provider) => DiveLog.message('$provider'));

    expect(
        DiveInputProviders.registerProvider(DiveInputProviders.all[0]), false);

    // Log the Dive inputs from the providers
    for (final provider in DiveInputProviders.all) {
      provider.inputs().then((inputs) {
        if (inputs != null) {
          for (final input in inputs) {
            DiveLog.message('$input');
          }
        }
      });
    }
  });
}
