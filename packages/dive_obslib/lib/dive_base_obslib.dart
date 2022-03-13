import 'dive_ffi_obslib.dart';
import 'dive_plugin_obslib.dart';

class DiveBaseObslib {
  /// Audio meter minumum level (dB)
  static const double audioMinLevel = -60.0;

  /// Must be called to initialize the FFI library and the Flutter plugin.
  void initialize() {
    DiveFFIObslib.initialize();
    setupChannels();
  }

  /// Start OBS. Load all modules, reset video and audio, and create the
  /// streaming service.
  ///
  /// Example:
  ///   startObs(1280, 720, 1280, 720, 30000, 1001);
  bool startObs(
    int baseWidth,
    int baseHeight,
    int outWidth,
    int outHeight,
    int fpsNumerator,
    int fpsDenominator,
  ) {
    try {
      if (!loadAllModules()) return false;
      if (!resetVideo(
        baseWidth,
        baseHeight,
        outWidth,
        outHeight,
        fpsNumerator,
        fpsDenominator,
      )) return false;
      if (!resetAudio()) return false;
    } catch (e) {
      print("startObs: exception: $e");
      return false;
    }
    return true;
  }
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
