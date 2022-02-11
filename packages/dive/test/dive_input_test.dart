// ignore_for_file: avoid_function_literals_in_foreach_calls

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

  test('DiveInputType statics', () {
    expect(DiveInputType.audio.name, 'Audio');
    expect(DiveInputType.audio.uuid, 'b3e12428-9406-4d00-995d-a2c09e627d17');
    expect(DiveInputType.image.name, 'Image');
    expect(DiveInputType.image.uuid, '433a04a4-bbd6-4fa7-9cdd-6dba51246b5f');
    expect(DiveInputType.media.name, 'Media');
    expect(DiveInputType.media.uuid, 'c8732afd-557a-4dde-80e0-797734cb5644');
    expect(DiveInputType.text.name, 'Text');
    expect(DiveInputType.text.uuid, 'e2621522-67a9-4747-becb-01e62b2920c6');
    expect(DiveInputType.video.name, 'Video');
    expect(DiveInputType.video.uuid, 'b11c0e88-0726-4889-8853-d801dc6c2c22');
  });

  test('DiveInputType fromMap', () {
    expect(DiveInputType.fromMap({}), null);
    expect(DiveInputType.fromMap({'name': 'name1'}), null);
    expect(DiveInputType.fromMap({'name': 'name1'}), null);
  });

  test('DiveInputType all', () {
    expect(DiveInputTypes.all.length, 5);
    expect(DiveInputTypes.all[0].name, 'Audio');
    expect(DiveInputTypes.all[1].name, 'Image');
    expect(DiveInputTypes.all[2].name, 'Media');
    expect(DiveInputTypes.all[3].name, 'Text');
    expect(DiveInputTypes.all[4].name, 'Video');

    // Log the Dive input types: audio, text, video, etc.
    DiveInputTypes.all.forEach((type) => DiveLog.message('$type'));

    final newType = DiveInputType.fromMap({'uuid': 'id1', 'name': 'name1'});
    expect(DiveInputTypes.registerNewInputType(newType!), true);
    DiveInputTypes.all.forEach((type) => DiveLog.message('$type'));

    expect(DiveInputTypes.registerNewInputType(newType), false);
    expect(DiveInputTypes.registerNewInputType(DiveInputType.audio), false);
  });
}
