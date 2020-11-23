import 'package:flutter/services.dart';
import 'package:dive_core/dive_device.dart';

class DivePlugin {
  static const String _channelName = 'dive_core.io/plugin';
  static const String _methodGetPlatformVersion = 'getPlatformVersion';
  static const String _methodGetDevicesDescription = 'getDevicesDescription';
  static const String _methodLoadImage = 'loadImage';
  static const String _methodDisposeTexture = 'disposeTexture';
  static const String _methodInitializeTexture = 'initializeTexture';
  static const String _methodGetDevices = 'getDevices';

  static const MethodChannel _channel = const MethodChannel(_channelName);

  static Future<String> platformVersion() async {
    // TODO: why can't this be complelety asynchronous and just remove this await?
    return await _channel.invokeMethod(_methodGetPlatformVersion);
  }

  static Future<String> devicesDescription() async {
    return await _channel.invokeMethod(_methodGetDevicesDescription);
  }

  static Future<String> loadImage([dynamic arguments]) async {
    return await _channel.invokeMethod(_methodLoadImage, arguments);
  }

  static Future<String> disposeTexture(int textureId) async {
    return await _channel
        .invokeMethod(_methodDisposeTexture, {"texture_id": textureId});
  }

  static Future<int> initializeTexture() async {
    return await _channel.invokeMethod(_methodInitializeTexture, {});
  }

  static Future<List<DiveDevice>> devices() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetDevices);
    return devices.map(DiveDevice.fromJson).toList();
  }
}
