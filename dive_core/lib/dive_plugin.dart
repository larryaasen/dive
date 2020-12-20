import 'package:dive_core/dive_sources.dart';
import 'package:flutter/services.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_core/dive_input.dart';

class DivePlugin {
  static const String _channelName = 'dive_core.io/plugin';
  static const String _methodGetPlatformVersion = 'getPlatformVersion';
  static const String _methodLoadImage = 'loadImage';
  static const String _methodDisposeTexture = 'disposeTexture';
  static const String _methodInitializeTexture = 'initializeTexture';

  static const String _methodGetInputTypes = 'getInputTypes';
  static const String _methodGetVideoInputs = 'getVideoInputs';
  static const String _methodAddSource = 'addSource';
  static const String _methodCreateImageSource = 'createImageSource';
  static const String _methodCreateMediaSource = 'createMediaSource';
  static const String _methodCreateVideoSource = 'createVideoSource';
  static const String _methodCreateVideoMix = 'createVideoMix';
  static const String _methodCreateScene = 'createScene';
  static const String _methodGetSceneItemInfo = 'getSceneItemInfo';
  static const String _methodSetSceneItemInfo = 'setSceneItemInfo';

  static const String _methodMediaPlayPause = 'mediaPlayPause';
  static const String _methodMediaStop = 'mediaStop';

  static const MethodChannel _channel = const MethodChannel(_channelName);

  DivePlugin();

  static Future<String> platformVersion() async {
    return await _channel.invokeMethod<String>(_methodGetPlatformVersion);
  }

  static Future<String> loadImage([dynamic arguments]) async {
    return await _channel.invokeMethod(_methodLoadImage, arguments);
  }

  static Future<String> disposeTexture(int textureId) async {
    return await _channel
        .invokeMethod(_methodDisposeTexture, {"texture_id": textureId});
  }

  static Future<int> initializeTexture({String trackingUUID}) async {
    return await _channel.invokeMethod(
        _methodInitializeTexture, {'tracking_uuid': trackingUUID});
  }

  static Future<List<DiveInputType>> inputTypes() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetInputTypes);
    return devices.map(DiveInputType.fromJson).toList();
  }

  static Future<List<DiveVideoInput>> videoInputs() async {
    final List<dynamic> devices =
        await _channel.invokeMethod(_methodGetVideoInputs);
    return devices.map(DiveVideoInput.fromMap).toList();
  }

  static Future<int> addSource(String sceneUUID, String sourceUUID) async {
    return await _channel.invokeMethod(
        _methodAddSource, {'scene_uuid': sceneUUID, 'source_uuid': sourceUUID});
  }

  static Future<bool> createImageSource(String sourceUUID, String file) async {
    return await _channel.invokeMethod(
        _methodCreateImageSource, {'source_uuid': sourceUUID, 'file': file});
  }

  static Future<bool> createMediaSource(
      String sourceUUID, String localFile) async {
    return await _channel.invokeMethod(_methodCreateMediaSource,
        {'source_uuid': sourceUUID, 'local_file': localFile});
  }

  static Future<bool> createVideoSource(
      String sourceUUID, String deviceName, String deviceUid) async {
    return await _channel.invokeMethod(_methodCreateVideoSource, {
      'source_uuid': sourceUUID,
      'device_name': deviceName,
      'device_uid': deviceUid
    });
  }

  static Future<bool> createVideoMix(String trackingUUID) async {
    return await _channel
        .invokeMethod(_methodCreateVideoMix, {'tracking_uuid': trackingUUID});
  }

  static Future<bool> createScene(String trackingUUID, String name) async {
    return await _channel.invokeMethod(
        _methodCreateScene, {'tracking_uuid': trackingUUID, 'name': name});
  }

  static Future<bool> mediaPlayPause(String sourceUUID, bool pause) async {
    return await _channel.invokeMethod(
        _methodMediaPlayPause, {'source_uuid': sourceUUID, 'pause': pause});
  }

  static Future<bool> mediaStop(String sourceUUID) async {
    return await _channel
        .invokeMethod(_methodMediaStop, {'source_uuid': sourceUUID});
  }

  static Future<DiveTransformInfo> getSceneItemInfo(
      String sceneUUID, int itemId) async {
    final Map info = await _channel.invokeMethod(
        _methodGetSceneItemInfo, {'scene_uuid': sceneUUID, 'item_id': itemId});
    return DiveTransformInfo.fromMap(info);
  }

  static Future<bool> setSceneItemInfo(
      String sceneUUID, int itemId, DiveTransformInfo info) async {
    return await _channel.invokeMethod(_methodSetSceneItemInfo,
        {'scene_uuid': sceneUUID, 'item_id': itemId, 'info': info.toMap()});
  }
}
