// import 'package:flutter/services.dart';
import 'package:dive_obslib/dive_obslib.dart';

/// Invokes methods on a channel to the plugin.
class DivePluginObslib extends DiveBaseObslib {
  // static const String _channelName = 'dive_obslib.io/plugin';
  // static const String _methodGetPlatformVersion = 'getPlatformVersion';
  // static const String _methodLoadImage = 'loadImage';
  // static const String _methodDisposeTexture = 'disposeTexture';
  // static const String _methodInitializeTexture = 'initializeTexture';

  // static const String _methodAddSourceFrameCallback = 'addSourceFrameCallback';

  // static const String _methodAddSource = 'addSource';
  // static const String _methodCreateSource = 'createSource';
  // static const String _methodCreateImageSource = 'createImageSource';
  // static const String _methodCreateMediaSource = 'createMediaSource';
  // static const String _methodCreateVideoSource = 'createVideoSource';
  // static const String _methodCreateVideoMix = 'createVideoMix';
  // static const String _methodCreateScene = 'createScene';
  // static const String _methodGetSceneItemInfo = 'getSceneItemInfo';
  // static const String _methodSetSceneItemInfo = 'setSceneItemInfo';

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

  // static const MethodChannel _channel = const MethodChannel(_channelName);

  @override
  void initialize() {}

  @override
  DivePointer createScene(String trackingUUID, String sceneName) {
    // final result = await _channel.invokeMethod(
    //     _methodCreateScene, {'tracking_uuid': trackingUUID, 'name': sceneName});
    return DivePointer(trackingUUID, 'ddd');
  }

  @override
  bool createService() {
    throw UnimplementedError();
  }

  @override
  bool loadAllModules() {
    throw UnimplementedError();
  }

  @override
  bool resetAudio() {
    throw UnimplementedError();
  }

  @override
  bool resetVideo(int width, int height) {
    throw UnimplementedError();
  }

  @override
  int addSource(DivePointer scene, DivePointer source) {
    throw UnimplementedError();
  }

  @override
  List<Map<String, String>> audioInputs() {
    throw UnimplementedError();
  }

  @override
  DivePointer createImageSource(String sourceUuid, String file) {
    throw UnimplementedError();
  }

  @override
  DivePointer createMediaSource(String sourceUuid, String localFile) {
    throw UnimplementedError();
  }

  @override
  DivePointer createSource(String sourceUuid, String sourceId, String name) {
    throw UnimplementedError();
  }

  @override
  DivePointer createVideoSource(
      String sourceUuid, String deviceName, String deviceUid) {
    throw UnimplementedError();
  }

  @override
  List<Map<String, String>> inputTypes() {
    throw UnimplementedError();
  }

  @override
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    throw UnimplementedError();
  }

  @override
  int mediaSourceGetDuration(DivePointer source) {
    throw UnimplementedError();
  }

  @override
  int mediaSourceGetState(DivePointer source) {
    throw UnimplementedError();
  }

  @override
  int mediaSourceGetTime(DivePointer source) {
    throw UnimplementedError();
  }

  @override
  void mediaSourcePlayPause(DivePointer source, bool pause) {}

  @override
  void mediaSourceRestart(DivePointer source) {}

  @override
  void mediaSourceSetTime(DivePointer source, int ms) {}

  @override
  void mediaSourceStop(DivePointer source) {}

  @override
  int outputGetState() {
    throw UnimplementedError();
  }

  @override
  Map sceneitemGetInfo(DivePointer scene, int itemId) {
    throw UnimplementedError();
  }

  @override
  bool streamOutputStart() {
    throw UnimplementedError();
  }

  @override
  void streamOutputStop() {}

  @override
  List<Map<String, String>> videoInputs() {
    throw UnimplementedError();
  }
}
