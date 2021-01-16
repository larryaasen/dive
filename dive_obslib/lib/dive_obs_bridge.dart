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

  bool startObs() {
    try {
      _startFFI();

      // FYI: Don't call obs_startup because it must run on the main thread
      // and FFI does not run on the main thread.
      int rv = 1;

      if (rv == 1) {
        _lib.obs_load_all_modules();
        _lib.obs_post_load_modules();
        if (!_resetVideo()) return false;
        if (!_resetAudio()) return false;

        // TODO: finish server setup after cameras are working.
        // if (!create_service()) return 0;

      } else {
        print("startObs: the call to obs_startup failed.");
        return false;
      }
    } catch (e) {
      print("startObs: exception: $e");
      return false;
    }
    return true;
  }

  void _startFFI() {
    _lib = DiveObslibFFILoad.loadLib();
  }

  // final locale = 'en'.toInt8();
  // final rv = _lib.obs_startup(locale, _lib.nullptr, _lib.nullptr);
  // free(locale);

  static const int cx = 1280;
  static const int cy = 720;

  bool _resetVideo() {
    final ovi = allocate<obs_video_info>().ref
      ..adapter = 0
      ..fps_num = 30000
      ..fps_den = 1001
      ..graphics_module = 'libobs-opengl'.toInt8() //DL_OPENGL
      ..output_format = video_format.VIDEO_FORMAT_RGBA
      ..base_width = cx
      ..base_height = cy
      ..output_width = cx
      ..output_height = cy
      ..colorspace = video_colorspace.VIDEO_CS_DEFAULT;

    int rv = _lib.obs_reset_video(ovi.addressOf);
    if (rv != OBS_VIDEO_SUCCESS) {
      print("Couldn't initialize video: $rv");
      return false; //throw "Couldn't initialize video";
    }
    return true;
  }

  bool _resetAudio() {
    final ai = allocate<obs_audio_info>().ref
      ..samples_per_sec = 48000
      ..speakers = speaker_layout.SPEAKERS_STEREO;
    int rv = _lib.obs_reset_audio(ai.addressOf);
    if (rv == 0) {
      print("Couldn't initialize audio: $rv");
      return false;
    }
    return true;
  }

  /// Create a new OBS scene.
  DiveBridgePointer createScene(String trackingUuid, String sceneName) {
    final name = sceneName.toInt8();
    final scene = _lib.obs_scene_create(name);
    free(name);
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

  /// Get a list of video capture inputs from input type `av_capture_input`.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> videoInputs() {
    return inputsFromType("av_capture_input");
  }

  /// Get a list of inputs from input type.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    final List<Map<String, String>> list = [];

    final typeId = inputTypeId.toInt8();
    final videoProps = _lib.obs_get_source_properties(typeId);
    free(typeId);

    if (videoProps != null) {
      ffi.Pointer<ffi.Pointer<obs_property>> propertyOut = allocate();

      var property = _lib.obs_properties_first(videoProps);
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
      _lib.obs_properties_destroy(videoProps);
    }
    return list;
  }
}
