import 'package:dive_core/src/dive_audio_meter_values.dart';
import 'package:test/test.dart';

void main() {
  group('Dive core tests', () {
    test('DiveAudioMeterValues', () {
      final state = DiveAudioMeterValues();
      expect(state.channelCount, 0);
    });
  });
}
