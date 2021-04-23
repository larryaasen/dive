import 'package:flutter/services.dart';
import 'package:dive_obslib/dive_obslib.dart';

/// Signature of VolumeMeter callback.
typedef VolumeMeterCallback = void Function(int volumeMeterPointer,
    List<dynamic> magnitude, List<dynamic> peak, List<dynamic> inputPeak);

/// Invokes methods on a channel to the plugin.
extension DivePluginObslib on DiveBaseObslib {
  // static const String _methodGetPlatformVersion = 'getPlatformVersion';
  // static const String _methodLoadImage = 'loadImage';
  static const String _methodDisposeTexture = 'disposeTexture';
  static const String _methodInitializeTexture = 'initializeTexture';

  static const String _methodAddSourceFrameCallback = 'addSourceFrameCallback';

  // static const String _methodAddSource = 'addSource';
  // static const String _methodCreateSource = 'createSource';
  // static const String _methodCreateImageSource = 'createImageSource';
  // static const String _methodCreateMediaSource = 'createMediaSource';
  // static const String _methodCreateVideoSource = 'createVideoSource';
  static const String _methodCreateVideoMix = 'createVideoMix';
  // static const String _methodCreateScene = 'createScene';
  static const String _methodGetSceneItemInfo = 'getSceneItemInfo';
  static const String _methodSetSceneItemInfo = 'setSceneItemInfo';

  // static const String _methodStartStopStream = 'startStopStream';
  // static const String _methodOutputGetState = 'outputGetState';

  // static const String _methodMediaPlayPause = 'mediaPlayPause';
  // static const String _methodMediaRestart = 'mediaRestart';
  // static const String _methodMediaStop = 'mediaStop';
  // static const String _methodMediaGetState = 'mediaGetState';

  // static const String _methodGetInputTypes = 'getInputTypes';
  // static const String _methodGetInputsFromType = 'getInputsFromType';
  // static const String _methodGetAudioInputs = 'getAudioInputs';
  // static const String _methodGetVideoInputs = 'getVideoInputs';

  static const String _methodAddVolumeMeterCallback = 'addVolumeMeterCallback';

  static const String _channelName = 'dive_obslib.io/plugin';
  static const String _channelNameCallback = 'dive_obslib.io/plugin/callback';

  static const MethodChannel _channel =
      const MethodChannel(DivePluginObslib._channelName);
  static const MethodChannel _channelCallback =
      const MethodChannel(DivePluginObslib._channelNameCallback);

  static final _volumeMeterCallbacks = Map<int, VolumeMeterCallback>();

  void setupChannels() {
    _channelCallback.setMethodCallHandler(callbacksHandler);
  }

  Future<dynamic> callbacksHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'volmeter':
        final volumeMeterPointer =
            methodCall.arguments['volmeter_pointer'] as int;
        var magnitude;
        try {
          magnitude = methodCall.arguments['magnitude'] as List<dynamic>;
        } catch (e) {
          print("exception: $e");
        }
        final peak = methodCall.arguments['peak'] as List<dynamic>;
        final inputPeak = methodCall.arguments['inputPeak'] as List<dynamic>;
        final callback = _volumeMeterCallbacks[volumeMeterPointer];
        if (callback != null) {
          try {
            callback(volumeMeterPointer, magnitude, peak, inputPeak);
          } catch (e) {
            print("callbacksHandler: exception calling callback: $e");
          }
        }
        return true;
      default:
        throw MissingPluginException('not implemented');
    }
  }

  Future<bool> addSourceFrameCallback(
      String sourceUUID, dynamic sourcePtr) async {
    return await _channel.invokeMethod(_methodAddSourceFrameCallback,
        {'source_uuid': sourceUUID, 'source_ptr': sourcePtr});
  }

  Future<bool> createVideoMix(String trackingUUID) async {
    return await _channel
        .invokeMethod(_methodCreateVideoMix, {'tracking_uuid': trackingUUID});
  }

  Future<String> disposeTexture(int textureId) async {
    return await _channel
        .invokeMethod(_methodDisposeTexture, {"texture_id": textureId});
  }

  Future<Map> getSceneItemInfoMap(int scenePointer, int itemId) {
    return _channel.invokeMethod(_methodGetSceneItemInfo,
        {'scene_pointer': scenePointer, 'item_id': itemId});
  }

  Future<int> initializeTexture({String trackingUUID}) async {
    return await _channel.invokeMethod(
        _methodInitializeTexture, {'tracking_uuid': trackingUUID});
  }

  Future<bool> setSceneItemInfo(int scenePointer, int itemId, Map info) {
    return _channel.invokeMethod(_methodSetSceneItemInfo,
        {'scene_pointer': scenePointer, 'item_id': itemId, 'info': info});
  }

  Future<int> addVolumeMeterCallback(
      int volumeMeterPointer, VolumeMeterCallback callback) {
    _volumeMeterCallbacks[volumeMeterPointer] = callback;
    return _channel.invokeMethod(_methodAddVolumeMeterCallback,
        {'volmeter_pointer': volumeMeterPointer});
  }

  Future<bool> removeVolumeMeterCallback(
      int volumeMeterPointer, VolumeMeterCallback callback) async {
    _volumeMeterCallbacks.remove(volumeMeterPointer);
    return true;
    // TODO: call the method to remove callback
  }

  // TODO: look at all of the returns with await and make them consistent.
}
