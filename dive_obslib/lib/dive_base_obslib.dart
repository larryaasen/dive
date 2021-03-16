import 'dive_pointer.dart';

abstract class DiveBaseObslib {
  void initialize() => throw UnimplementedError();

  /// Start OBS. Load all modules, reset video and audio, and create the
  /// streaming service.
  ///
  /// Example:
  ///   startObs(1280, 720);
  bool startObs(int width, int height) {
    try {
      if (!resetVideo(width, height)) return false;
      if (!resetAudio()) return false;

      // Create streaming service
      return createService();
    } catch (e) {
      print("startObs: exception: $e");
      return false;
    }
  }

  bool loadAllModules();
  bool resetVideo(int width, int height);
  bool resetAudio();
  bool createService();

  DivePointer createScene(String trackingUUID, String sceneName);
  DivePointer createImageSource(String sourceUuid, String file);
  DivePointer createMediaSource(String sourceUuid, String localFile);
  DivePointer createVideoSource(
      String sourceUuid, String deviceName, String deviceUid);
  DivePointer createSource(String sourceUuid, String sourceId, String name);
  int addSource(DivePointer scene, DivePointer source);
  Map sceneitemGetInfo(DivePointer scene, int itemId);
  bool streamOutputStart();
  void streamOutputStop();
  int outputGetState();
  void mediaSourcePlayPause(DivePointer source, bool pause);
  void mediaSourceRestart(DivePointer source);
  void mediaSourceStop(DivePointer source);
  int mediaSourceGetDuration(DivePointer source);
  int mediaSourceGetTime(DivePointer source);
  void mediaSourceSetTime(DivePointer source, int ms);
  int mediaSourceGetState(DivePointer source);
  List<Map<String, String>> inputTypes();
  List<Map<String, String>> inputsFromType(String inputTypeId);
  List<Map<String, String>> audioInputs();
  List<Map<String, String>> videoInputs();
}

/// Audio Source Types

abstract class DiveObsAudioSourceTypeApple {
  static const String INPUT_AUDIO_SOURCE = 'coreaudio_input_capture';
  static const String OUTPUT_AUDIO_SOURCE = 'coreaudio_output_capture';
}

abstract class DiveObsAudioSourceTypeWin32 {
  static const String INPUT_AUDIO_SOURCE = 'wasapi_input_capture';
  static const String OUTPUT_AUDIO_SOURCE = 'wasapi_output_capture';
}

abstract class DiveObsAudioSourceTypeOther {
  static const String INPUT_AUDIO_SOURCE = 'pulse_input_capture';
  static const String OUTPUT_AUDIO_SOURCE = 'pulse_output_capture';
}

abstract class DiveObsAudioSourceType {
  // TODO: return based on OS
  // ignore: non_constant_identifier_names
  static String get INPUT_AUDIO_SOURCE =>
      DiveObsAudioSourceTypeApple.INPUT_AUDIO_SOURCE;
  // ignore: non_constant_identifier_names
  static String get OUTPUT_AUDIO_SOURCE =>
      DiveObsAudioSourceTypeApple.OUTPUT_AUDIO_SOURCE;
}
