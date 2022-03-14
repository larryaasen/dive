import 'package:dive/dive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  tearDown(() {});

  test('testing DiveUuid', () async {
    expect(DiveUuid.newId(), isNotEmpty);
  });

  test('formatDuration', () {
    final fmt = DiveFormat.formatDuration;
    expect(fmt(Duration(milliseconds: 21)), '0.021');
    expect(fmt(Duration(milliseconds: 321)), '0.321');
    expect(fmt(Duration(milliseconds: 4321)), '00:04');
    expect(fmt(Duration(milliseconds: 54321)), '00:54');
    expect(fmt(Duration(milliseconds: 654321)), '10:54');
    expect(fmt(Duration(seconds: 7654, milliseconds: 321)), '2:07:34');
    expect(fmt(Duration(seconds: 27654, milliseconds: 321)), '7:40:54');
    expect(fmt(Duration(seconds: 37654, milliseconds: 321)), '10:27:34');
    expect(fmt(Duration(seconds: 47654, milliseconds: 321)), '13:14:14');
    expect(fmt(Duration(seconds: 57654, milliseconds: 321)), '16:00:54');
    expect(fmt(Duration(seconds: 67654, milliseconds: 321)), '18:47:34');
    expect(fmt(Duration(seconds: 77654, milliseconds: 321)), '21:34:14');
  });
}
