import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dive_video_source/dive_video_source.dart';

void main() {
  const MethodChannel channel = MethodChannel('dive_video_source');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await DiveVideoSource.platformVersion, '42');
  });
}
