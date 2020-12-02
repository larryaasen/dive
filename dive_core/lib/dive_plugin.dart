import 'package:flutter/services.dart';
import 'package:dive_core/dive_device.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';

class DivePlugin {
  static const String _channelName = 'dive_core.io/plugin';
  static const String _methodGetPlatformVersion = 'getPlatformVersion';
  static const String _methodGetDevicesDescription = 'getDevicesDescription';
  static const String _methodLoadImage = 'loadImage';
  static const String _methodDisposeTexture = 'disposeTexture';
  static const String _methodInitializeTexture = 'initializeTexture';
  static const String _methodGetDevices = 'getDevices';

  static const String _methodGetInputTypes = 'getInputTypes';
  static const String _methodGetVideoInputs = 'getVideoInputs';
  static const String _methodCreateSource = 'createSource';

  static const MethodChannel _channel = const MethodChannel(_channelName);

  static Future<String> platformVersion() async {
    return await _channel.invokeMethod<String>(_methodGetPlatformVersion);
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

  static Future<int> initializeTexture({String name, String sourceId}) async {
    return await _channel.invokeMethod(
        _methodInitializeTexture, {'name': name, 'source_id': sourceId});
  }

  static Future<List<DiveDevice>> devices() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetDevices);
    return devices.map(DiveDevice.fromJson).toList();
  }

  static Future<List<DiveInputType>> inputTypes() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetInputTypes);
    return devices.map(DiveInputType.fromJson).toList();
  }

  static Future<List<DiveVideoInput>> videoInputs() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetVideoInputs);
    return devices.map(DiveVideoInput.fromJson).toList();
  }

  static Future<bool> createSource(
      String deviceName, String deviceUid, bool isTextureSource) async {
    return await _channel.invokeMethod(_methodCreateSource, {
      'device_name': deviceName,
      'device_uid': deviceUid,
      'is_frame_source': isTextureSource
    });
  }
}
