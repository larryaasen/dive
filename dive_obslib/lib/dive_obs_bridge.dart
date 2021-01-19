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

  /// Get a list of video capture inputs from input type `av_capture_input`.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> videoInputs() {
    return inputsFromType("av_capture_input");
  }

  /// Get a list of inputs from input type.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    final List<Map<String, String>> list = [];

    final videoProps = _lib.obs_get_source_properties(inputTypeId.int8());

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
    StringExtensions.freeInt8s();

    return list;
  }

  DiveBridgePointer createVideoSource(
      String sourceUuid, String deviceName, String deviceUid) {
    final settings = _lib.obs_data_create();
    _lib.obs_data_set_string(settings, "device_name".int8(), deviceName.int8());
    _lib.obs_data_set_string(settings, "device".int8(), deviceUid.int8());
    StringExtensions.freeInt8s();

    // TODO: creating a video source breaks the Flutter connection to the device.
    final source =
        createSource(sourceUuid, "av_capture_input", "camera", settings, true);

    return source;
  }

  // static const except = -1;

  /// If you see this message: The method 'FfiTrampoline' was called on null
  /// make sure to use nullptr instead of null.
  /// https://github.com/dart-lang/sdk/issues/39804#

  DiveBridgePointer createSource(String sourceUuid, String sourceId,
      String name, ffi.Pointer<obs_data> settings, bool frameSource) {
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
    int item_id = _lib.obs_sceneitem_get_id(item);

    return item_id;
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

  Map _convert_transform_vec2_to_dict(vec2 vec) {
    return {"x": vec.x, "y": vec.y};
  }

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

}

void sourceFrameCallback(ffi.Pointer<ffi.Void> param,
    ffi.Pointer<obs_source> source, ffi.Pointer<obs_source_frame> frame) {
  print("sourceFrameCallback called");
  // TODO: finish this

  // const char *uuid_str = source_uuid_list[source];
  // if (uuid_str == NULL) {
  //     printf("%s: unknown source %s\n", __func__, uuid_str);
  //     return;
  // }

  // @synchronized (_textureSources) {
  //     TextureSource *textureSource = _textureSourceMap[uuid_str];
  //     if (textureSource != NULL) {
  //         copy_source_frame_to_texture(frame, textureSource);
  //     } else {
  //         printf("%s: no texture source for %s\n", __func__, uuid_str);
  //     }
  // }
}
