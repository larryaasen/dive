import 'package:flutter/services.dart';
import 'package:dive_obslib/dive_obslib.dart';

/// Signature of VolumeMeter callback.
typedef DiveVolumeMeterCallback = void Function(int volumeMeterPointer,
    List<double> magnitude, List<double> peak, List<double> inputPeak);

/// Invokes methods on a channel to the plugin.
extension DivePluginObslib on DiveBaseObslib {
  static const String _methodDisposeTexture = 'disposeTexture';
  static const String _methodInitializeTexture = 'initializeTexture';
  static const String _methodAddSourceFrameCallback = 'addSourceFrameCallback';
  static const String _methodCreateVideoMix = 'createVideoMix';
  static const String _methodRemoveVideoMix = 'removeVideoMix';
  static const String _methodChangeFrameRate = 'changeFrameRate';
  static const String _methodChangeResolution = 'changeResolution';
  static const String _methodGetSceneItemInfo = 'getSceneItemInfo';
  static const String _methodSetSceneItemInfo = 'setSceneItemInfo';
  static const String _methodAddVolumeMeterCallback = 'addVolumeMeterCallback';

  static const String _channelName = 'dive_obslib.io/plugin';
  static const String _channelNameCallback = 'dive_obslib.io/plugin/callback';

  static const MethodChannel _channel =
      const MethodChannel(DivePluginObslib._channelName);
  static const MethodChannel _channelCallback =
      const MethodChannel(DivePluginObslib._channelNameCallback);

  static final _volumeMeterCallbacks = Map<int, DiveVolumeMeterCallback>();

  void setupChannels() {
    _channelCallback.setMethodCallHandler(callbacksHandler);
  }

  Future<dynamic> callbacksHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'volmeter':
        final volumeMeterPointer =
            methodCall.arguments['volmeter_pointer'] as int;

        var magnitude, peak, inputPeak;
        try {
          magnitude = methodCall.arguments['magnitude'].cast<double>().toList();
          peak = methodCall.arguments['peak'].cast<double>().toList();
          inputPeak = methodCall.arguments['inputPeak'].cast<double>().toList();
        } catch (e, s) {
          print("exception: $e\n$s");
        }

        final callback = _volumeMeterCallbacks[volumeMeterPointer];
        if (callback != null) {
          try {
            callback(volumeMeterPointer, magnitude, peak, inputPeak);
          } catch (e, s) {
            print(
                "DivePluginObslib.callbacksHandler: exception calling callback: $e\n$s");
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
    final rv = await _channel
        .invokeMethod(_methodCreateVideoMix, {'tracking_uuid': trackingUUID});
    return rv;
  }

  Future<bool> removeVideoMix(String trackingUUID) async {
    final rv = await _channel
        .invokeMethod(_methodRemoveVideoMix, {'tracking_uuid': trackingUUID});
    return rv;
  }

  Future<bool> changeFrameRate(int numerator, int denominator) async {
    final rv = await _channel.invokeMethod(_methodChangeFrameRate,
        {'numerator': numerator, 'denominator': denominator});
    return rv;
  }

  Future<bool> changeResolution(
      int baseWidth, int baseHeight, int outputWidth, int outputHeight) async {
    final rv = await _channel.invokeMethod(_methodChangeResolution, {
      'base_width': baseWidth,
      'base_height': baseHeight,
      'output_width': outputWidth,
      'output_height': outputHeight
    });
    return rv;
  }

  Future<String> disposeTexture(int textureId) async {
    return await _channel
        .invokeMethod(_methodDisposeTexture, {"texture_id": textureId});
  }

  Future<Map> getSceneItemInfoMap(int itemPointer) {
    return _channel.invokeMethod(
        _methodGetSceneItemInfo, {'sceneitem_pointer': itemPointer});
  }

  Future<int> initializeTexture({String trackingUUID}) async {
    return await _channel.invokeMethod(
        _methodInitializeTexture, {'tracking_uuid': trackingUUID});
  }

  Future<bool> setSceneItemInfo(int itemPointer, Map info) {
    return _channel.invokeMethod(_methodSetSceneItemInfo,
        {'sceneitem_pointer': itemPointer, 'info': info});
  }

  Future<int> addVolumeMeterCallback(
      int volumeMeterPointer, DiveVolumeMeterCallback callback) {
    _volumeMeterCallbacks[volumeMeterPointer] = callback;
    return _channel.invokeMethod(_methodAddVolumeMeterCallback,
        {'volmeter_pointer': volumeMeterPointer});
  }

  Future<bool> removeVolumeMeterCallback(
      int volumeMeterPointer, DiveVolumeMeterCallback callback) async {
    _volumeMeterCallbacks.remove(volumeMeterPointer);
    return true;
    // TODO: call the method to remove callback
  }

  // TODO: look at all of the returns with await and make them consistent.
}
