import 'package:flutter_test/flutter_test.dart';
import 'package:dive_obslib/dive_obslib.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    expect(obslib, isNotNull);
  });

  tearDown(() {});

  test('testing DivePointer', () async {
    final pointer = DivePointer('abc', null);
    expect(pointer, isNotNull);
    expect(pointer.trackingUuid, 'abc');
  });

  test('testing startObs', () async {
    final rv = obslib.startObs(100, 100, 100, 100, 30, 10);
    expect(rv, isFalse);
  });

  // test('testing createScene', () async {
  //   var pointer;

  //   pointer = obslib.createScene('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });

  // test('testing createMediaSource', () async {
  //   var pointer;

  //   pointer = obslib.createMediaSource('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });

  // test('testing Plugin obslib', () async {
  //   var pointer;

  //   final plugin = DivePluginObslib()..initialize();
  //   expect(plugin, isNotNull);
  //   pointer = plugin.createScene('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });

  // test('testing FFI obslib', () async {
  //   var pointer;

  //   final ffi = DiveFFIObslib()..initialize();
  //   expect(ffi, isNotNull);
  //   pointer = ffi.createScene('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });
}
