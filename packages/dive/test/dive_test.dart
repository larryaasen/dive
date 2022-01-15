import 'package:dive/dive.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  tearDown(() {});

  test('DiveInput', () {
    final input =
        DiveInput(name: 'test1', id: 'id1', type: DiveInputType.audio);
    expect(input.name, 'test1');
    expect(input.id, 'id1');
    expect(input.type.name, 'Audio');
    expect(input.type.uuid, 'b3e12428-9406-4d00-995d-a2c09e627d17');

    expect(DiveInput.fromMap({}), null);
    expect(DiveInput.fromMap({'id': 'id1'}), null);
    expect(DiveInput.fromMap({'id': 'id1', 'name': 'name1'}), null);
    final in2 = DiveInput.fromMap(
        {'id': 'id1', 'name': 'name1', 'type': DiveInputType.audio});
    expect(in2?.id, 'id1');
    expect(in2?.name, 'name1');
    expect(in2?.type.name, 'Audio');
    expect(in2?.type.uuid, 'b3e12428-9406-4d00-995d-a2c09e627d17');
  });

  test('formatDuration', () {
    final fmt = DiveFormat.formatDuration;
    expect(fmt(Duration(milliseconds: 21)), '0.021');
    expect(fmt(Duration(milliseconds: 321)), '0.321');
    expect(fmt(Duration(milliseconds: 4321)), '4.321');
    expect(fmt(Duration(milliseconds: 54321)), '54.321');
    expect(fmt(Duration(milliseconds: 654321)), '10:54.321');
    expect(fmt(Duration(seconds: 7654, milliseconds: 321)), '2:07:34.321');
    expect(fmt(Duration(seconds: 27654, milliseconds: 321)), '7:40:54.321');
    expect(fmt(Duration(seconds: 37654, milliseconds: 321)), '10:27:34.321');
    expect(fmt(Duration(seconds: 47654, milliseconds: 321)), '13:14:14.321');
    expect(fmt(Duration(seconds: 57654, milliseconds: 321)), '16:00:54.321');
    expect(fmt(Duration(seconds: 67654, milliseconds: 321)), '18:47:34.321');
    expect(fmt(Duration(seconds: 77654, milliseconds: 321)), '21:34:14.321');
  });

  test('image input provider', () {
    const filename = '/Users/larry/Downloads/IMG_8384.jpg';
    final imageProvider = DiveImageInputProvider();
    final imageSource = imageProvider.create(
        "image1",
        DiveCoreProperties.fromMap(
            {DiveImageInputProvider.PROPERTY_FILENAME: filename}));
    final output1 =
        DiveOutput(name: 'output1', frameInput: imageSource?.frameOutput);
    output1.start();
    Future.delayed(Duration(seconds: 2), () {
      final output2 =
          DiveOutput(name: 'output2', frameInput: imageSource?.frameOutput);
      output2.start();

      Future.delayed(Duration(seconds: 2), () {
        final output3 =
            DiveOutput(name: 'output3', frameInput: imageSource?.frameOutput);
        final output4 =
            DiveOutput(name: 'output4', frameInput: imageSource?.frameOutput);
        output3.start();
        output4.start();

        Future.delayed(Duration(seconds: 2));
      });
    });
  });
}
