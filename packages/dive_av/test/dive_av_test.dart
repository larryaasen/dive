import 'package:dive_av/dive_av_method_channel.dart';
import 'package:dive_av/dive_av_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockDiveAvPlatform
//     with MockPlatformInterfaceMixin
//     implements DiveAvPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

void main() {
  final DiveAvPlatform initialPlatform = DiveAvPlatform.instance;

  test('$MethodChannelDiveAv is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDiveAv>());
  });

  // test('getPlatformVersion', () async {
  //   DiveAv diveAvPlugin = DiveAv();
  //   // MockDiveAvPlatform fakePlatform = MockDiveAvPlatform();
  //   // DiveAvPlatform.instance = fakePlatform;

  //   expect(await diveAvPlugin.getPlatformVersion(), '42');
  // });
}
