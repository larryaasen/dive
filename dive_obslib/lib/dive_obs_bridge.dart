import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'dive_obs_ffi.dart';
import 'dive_ffi_load.dart';
import 'dive_bridge_pointer.dart';

class DiveObsBridge {
  DiveObsBridge();

  DiveObslibFFI _lib;

  /// Tracks the first scene being created, and sets the output source if first
  bool _isFirstScene = true;

  /// The streaming service output.
  var _streamOutput;

  // FYI: Don't call obs_startup because it must run on the main thread
  // and FFI does not run on the main thread.

  /// Start OBS.
  ///
  /// Example:
  ///   startObs(1280, 720);
  bool startObs(int width, int height) {
    try {
      _startFFI();

      _lib.obs_load_all_modules();
      _lib.obs_post_load_modules();
      if (!_resetVideo(width, height)) return false;
      if (!_resetAudio()) return false;

      // Create streaming service
      return createService();
    } catch (e) {
      print("startObs: exception: $e");
      return false;
    }
  }

  void _startFFI() {
    _lib = DiveObslibFFILoad.loadLib();
  }

  bool _resetVideo(int width, int height) {
    final ovi = allocate<obs_video_info>();
    ovi.ref
      ..adapter = 0
      ..fps_num = 30000
      ..fps_den = 1001
      ..graphics_module = 'libobs-opengl'.toInt8() //DL_OPENGL
      ..output_format = video_format.VIDEO_FORMAT_RGBA
      ..base_width = width
      ..base_height = height
      ..output_width = width
      ..output_height = height
      ..colorspace = video_colorspace.VIDEO_CS_DEFAULT;

    int rv = _lib.obs_reset_video(ovi);
    if (rv != OBS_VIDEO_SUCCESS) {
      print("Couldn't initialize video: $rv");
      return false; //throw "Couldn't initialize video";
    }
    return true;
  }

  bool _resetAudio() {
    final ai = allocate<obs_audio_info>();
    ai.ref
      ..samples_per_sec = 48000
      ..speakers = speaker_layout.SPEAKERS_STEREO;
    int rv = _lib.obs_reset_audio(ai);
    if (rv == 0) {
      print("Couldn't initialize audio: $rv");
      return false;
    }
    return true;
  }

  /// Create a new OBS scene.
  DiveBridgePointer createScene(String trackingUuid, String sceneName) {
    final scene = _lib.obs_scene_create(sceneName.int8());
    StringExtensions.freeInt8s();
    if (scene == null) {
      print("Couldn't create scene: $sceneName");
      return null;
    }

    if (_isFirstScene) {
      _isFirstScene = false;

      // set the scene as the primary draw source and go
      final channel = 0;
      _lib.obs_set_output_source(channel, _lib.obs_scene_get_source(scene));
    }

    return DiveBridgePointer(trackingUuid, scene);
  }

  DiveBridgePointer createImageSource(String sourceUuid, String file) {
    final settings = _lib.obs_data_create();
    _lib.obs_data_set_string(settings, "file".int8(), file.int8());

    return _createSourceInternal(sourceUuid, "image_source", "image", settings);
  }

  DiveBridgePointer createMediaSource(String sourceUuid, String localFile) {
    // Load video file
    final settings = _lib.obs_get_source_defaults("ffmpeg_source".int8());
    _lib.obs_data_set_bool(settings, "is_local_file".int8(), 1);
    _lib.obs_data_set_bool(settings, "looping".int8(), 0);
    _lib.obs_data_set_bool(settings, "clear_on_media_end".int8(), 0);
    _lib.obs_data_set_bool(settings, "close_when_inactive".int8(), 1);
    _lib.obs_data_set_bool(settings, "restart_on_activate".int8(), 0);
    _lib.obs_data_set_string(settings, "local_file".int8(), localFile.int8());

    return _createSourceInternal(
        sourceUuid, "ffmpeg_source", "video file", settings);
  }

  DiveBridgePointer createVideoSource(
    String sourceUuid,
    String deviceName,
    String deviceUid,
  ) {
    final settings = _lib.obs_data_create();
    _lib.obs_data_set_string(settings, "device_name".int8(), deviceName.int8());
    _lib.obs_data_set_string(settings, "device".int8(), deviceUid.int8());

    // TODO: creating a video source breaks the Flutter connection to the device.
    return _createSourceInternal(
        sourceUuid, "av_capture_input", "camera", settings);
  }

  DiveBridgePointer createSource(
    String sourceUuid,
    String sourceId,
    String name,
  ) {
    final source = _lib.obs_source_create(
        sourceId.int8(), name.int8(), ffi.nullptr, ffi.nullptr);
    StringExtensions.freeInt8s();
    if (source.address == 0) {
      print("Could not create source");
      return null;
    }

    return DiveBridgePointer(sourceUuid, source);
  }

  // static const except = -1;

  /// If you see this message: The method 'FfiTrampoline' was called on null
  /// make sure to use nullptr instead of null.
  /// https://github.com/dart-lang/sdk/issues/39804#

  DiveBridgePointer _createSourceInternal(
    String sourceUuid,
    String sourceId,
    String name,
    ffi.Pointer<obs_data> settings,
  ) {
    final source = _lib.obs_source_create(
        sourceId.int8(), name.int8(), settings, ffi.nullptr);
    StringExtensions.freeInt8s();
    if (source.address == 0) {
      print("Could not create source");
      return null;
    }

    return DiveBridgePointer(sourceUuid, source);
  }

  /// Add an existing source to an existing scene, and return
  int addSource(DiveBridgePointer scene, DiveBridgePointer source) {
    final item = _lib.obs_scene_add(scene.pointer, source.pointer);
    return _lib.obs_sceneitem_get_id(item);
  }

  /// Get the transform info for a scene item.
  Map sceneitemGetInfo(DiveBridgePointer scene, int itemId) {
    if (itemId < 1) {
      print("invalid item id $itemId");
      return null;
    }

    // final item = _lib.obs_scene_find_sceneitem_by_id(scene.pointer, itemId);
    // obs_transform_info info;
    // _lib.obs_sceneitem_get_info(item, info);
    // TODO: finish this
    return null; // _convert_transform_info_to_dict(info);
  }

  // Map _convert_transform_vec2_to_dict(vec2 vec) {
  //   return {"x": vec.x, "y": vec.y};
  // }

  // Map _convert_transform_info_to_dict(obs_transform_info info) {
  //   return {
  //         "pos": _convert_transform_vec2_to_dict(info.pos),
  //         "rot": info.rot,
  //         "scale": _convert_transform_vec2_to_dict(info.scale),
  //         "alignment": info->alignment,
  //         "bounds_type": bounds_type,
  //         "bounds_alignment": info->bounds_alignment,
  //         "bounds": _convert_transform_vec2_to_dict(info.bounds)
  //     };
  // }

  /// Stream Controls

  /// Start the stream output.
  bool streamOutputStart() {
    final rv = _lib.obs_output_start(_streamOutput);
    if (rv != 1) {
      print("stream not started");
    }
    return rv == 1;
  }

  /// Stop the stream output.
  void streamOutputStop() {
    _lib.obs_output_stop(_streamOutput);
  }

  /// Get the output state: 1 (active), 2 (paused), or 3 (reconnecting)
  int outputGetState() {
    final active = _lib.obs_output_active(_streamOutput);
    final paused = _lib.obs_output_paused(_streamOutput);
    final reconnecting = _lib.obs_output_reconnecting(_streamOutput);
    int state = 0;
    if (active == 1)
      state = 1;
    else if (paused == 1)
      state = 2;
    else if (reconnecting == 1) state = 3;

    return state;
  }

  bool createService() {
    final serviceSettings = _lib.obs_data_create();
    final url = "rtmp://live-iad05.twitch.tv/app/<your_stream_key>";
    final key = "<your_stream_key>";
    _lib.obs_data_set_string(serviceSettings, "server".int8(), url.int8());
    _lib.obs_data_set_string(serviceSettings, "key".int8(), key.int8());

    final serviceId = "rtmp_common";
    final serviceObj = _lib.obs_service_create(serviceId.int8(),
        "default_service".int8(), serviceSettings, ffi.nullptr);
    //  _lib.obs_service_release(service_obj);

    final type = "rtmp_output";
    _streamOutput = _lib.obs_output_create(
        type.int8(), "adv_stream".int8(), ffi.nullptr, ffi.nullptr);
    if (_streamOutput == null) {
      print("creation of stream output type $type failed");
      return false;
    }

    final vencoder = _lib.obs_video_encoder_create(
        "obs_x264".int8(), "test_x264".int8(), ffi.nullptr, ffi.nullptr);
    //  _lib.obs_encoder_release(vencoder);
    final aencoder = _lib.obs_audio_encoder_create(
        "ffmpeg_aac".int8(), "test_aac".int8(), ffi.nullptr, 0, ffi.nullptr);
    //  _lib.obs_encoder_release(aencoder);
    _lib.obs_encoder_set_video(vencoder, _lib.obs_get_video());
    _lib.obs_encoder_set_audio(aencoder, _lib.obs_get_audio());
    _lib.obs_output_set_video_encoder(_streamOutput, vencoder);
    _lib.obs_output_set_audio_encoder(_streamOutput, aencoder, 0);

    _lib.obs_output_set_service(_streamOutput, serviceObj);

    final outputSettings = _lib.obs_data_create();
    _lib.obs_data_set_string(
        outputSettings, "bind_ip".int8(), "default".int8());
    _lib.obs_data_set_bool(outputSettings, "new_socket_loop_enabled".int8(), 0);
    _lib.obs_data_set_bool(
        outputSettings, "low_latency_mode_enabled".int8(), 0);
    _lib.obs_data_set_bool(outputSettings, "dyn_bitrate".int8(), 0);
    _lib.obs_output_update(_streamOutput, outputSettings);

    // if (_lib.obs_output_start(stream_output) == 0) {
    //   print("output start failed");
    //   return false;
    // }

    return true;
  }

  /// Media Controls
  /// TODO: implement signals from media source: obs_source_get_signal_handler

  /// Media control: play_pause
  void mediaSourcePlayPause(DiveBridgePointer source, bool pause) {
    _lib.obs_source_media_play_pause(source.pointer, pause ? 1 : 0);
  }

  /// Media control: restart
  void mediaSourceRestart(DiveBridgePointer source) {
    _lib.obs_source_media_restart(source.pointer);
  }

  /// Media control: stop
  void mediaSourceStop(DiveBridgePointer source) {
    _lib.obs_source_media_stop(source.pointer);
  }

  /// Media control: get time
  int mediaSourceGetDuration(DiveBridgePointer source) {
    return _lib.obs_source_media_get_duration(source.pointer);
  }

  /// Media control: get time
  int mediaSourceGetTime(DiveBridgePointer source) {
    return _lib.obs_source_media_get_time(source.pointer);
  }

  /// Media control: set time
  void mediaSourceSetTime(DiveBridgePointer source, int ms) {
    _lib.obs_source_media_set_time(source.pointer, ms);
  }

  /// Media control: get state
  int mediaSourceGetState(DiveBridgePointer source) {
    return _lib.obs_source_media_get_state(source.pointer);
  }

  /// Get a list of input types.
  /// Returns array of dictionaries with keys `id` and `name`.
  List<Map<String, String>> inputTypes() {
    int idx = 0;
    final List<Map<String, String>> list = [];

    ffi.Pointer<ffi.Pointer<ffi.Int8>> typeId = allocate();
    ffi.Pointer<ffi.Pointer<ffi.Int8>> unversionedTypeId = allocate();

    while (_lib.obs_enum_input_types2(idx++, typeId, unversionedTypeId) != 0) {
      final name = _lib.obs_source_get_display_name(typeId.value);
      final caps = _lib.obs_get_source_output_flags(typeId.value);

      if ((caps & OBS_SOURCE_CAP_DISABLED) != 0) continue;

      bool deprecated = (caps & OBS_SOURCE_DEPRECATED) != 0;
      if (deprecated) {
      } else {}

      list.add({
        "id": StringExtensions.fromInt8(unversionedTypeId.value),
        "name": StringExtensions.fromInt8(name)
      });
    }
    return list;
  }

  /// Get a list of inputs from input type.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    final List<Map<String, String>> list = [];

    final sourceProps = _lib.obs_get_source_properties(inputTypeId.int8());

    if (sourceProps != null) {
      ffi.Pointer<ffi.Pointer<obs_property>> propertyOut = allocate();

      var property = _lib.obs_properties_first(sourceProps);
      while (property != null) {
        final type = _lib.obs_property_get_type(property);
        if (type == obs_property_type.OBS_PROPERTY_LIST) {
          final count = _lib.obs_property_list_item_count(property);
          for (int index = 0; index < count; index++) {
            final disabled =
                _lib.obs_property_list_item_disabled(property, index);
            final name = _lib.obs_property_list_item_name(property, index);
            final uid = _lib.obs_property_list_item_string(property, index);
            if (disabled == 0 &&
                name.address != 0 &&
                uid.address != 0 &&
                StringExtensions.fromInt8(name).isNotEmpty &&
                StringExtensions.fromInt8(uid).isNotEmpty) {
              list.add({
                "id": StringExtensions.fromInt8(uid),
                "name": StringExtensions.fromInt8(name),
                "type_id": inputTypeId
              });
            }
          }
        }
        propertyOut.value = property;
        final rv = _lib.obs_property_next(propertyOut);
        property = rv == 1 ? propertyOut.value : null;
      }
      _lib.obs_properties_destroy(sourceProps);
    }
    StringExtensions.freeInt8s();

    return list;
  }

  /// Get a list of video capture inputs from input type `coreaudio_input_capture`.
  /// @return array of dictionaries with keys `id` and `name`.
  List<Map<String, String>> audioInputs() {
    return inputsFromType(DiveObsAudioSourceType.INPUT_AUDIO_SOURCE);
  }

  /// Get a list of video capture inputs from input type `av_capture_input`.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> videoInputs() {
    return inputsFromType("av_capture_input");
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