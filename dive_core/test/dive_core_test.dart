import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dive_core/dive_plugin.dart';
import 'package:dive_core/dive_format.dart';

void main() {
  const MethodChannel channel = MethodChannel('dive_core');

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
    expect(await DivePlugin.platformVersion(), '42');
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
}
