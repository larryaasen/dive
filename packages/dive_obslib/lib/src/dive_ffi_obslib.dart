import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'dive_base_obslib.dart';
import 'dive_ffi_load.dart';
import 'dive_obs_ffi.dart';
import 'dive_pointer.dart';

/// The FFI loaded libobs library.
late DiveObslibFFI _lib;

bool _initialized = false;

/// Tracks the first scene being created, and sets the output source if first
bool _isFirstScene = true;

bool _debugVerbose = false;

/// Connects to obslib using FFI. Will load the obslib library, load modules,
/// reset video and audio, and create the streaming service.
extension DiveFFIObslib on DiveBaseObslib {
  // FYI: Don't call obs_startup because it must run on the main thread
  // and FFI does not run on the main thread.

  void _assertInitialized() {
    assert(_initialized, 'call initialize() before calling this method.');
  }

  static void initialize() {
    assert(!_initialized, 'initialize() has already been called once.');
    _lib = DiveObslibFFILoad.loadLib();
    _initialized = true;
  }

  bool loadAllModules() {
    if (_debugVerbose) print("dive_obslib: load_all_modules");
    _lib.obs_load_all_modules();
    _lib.obs_post_load_modules();
    if (_debugVerbose) print("dive_obslib: post_load_modules");
    return true;
  }

  /// Reset OBS video.
  ///
  /// Example:
  ///   resetVideo(1280, 720, 1280, 720, 30000, 1001);
  bool resetVideo(
    int baseWidth,
    int baseHeight,
    int outWidth,
    int outHeight,
    int fpsNumerator,
    int fpsDenominator,
  ) {
    final ovi = calloc<obs_video_info>();
    ovi.ref
      ..adapter = 0
      ..fps_num = fpsNumerator // Output FPS numerator
      ..fps_den = fpsDenominator // Output FPS denominator
      ..graphics_module = 'libobs-opengl'.toInt8() //DL_OPENGL
      ..base_width = baseWidth
      ..base_height = baseHeight
      ..output_width = outWidth
      ..output_height = outHeight
      ..output_format = video_format.VIDEO_FORMAT_RGBA
      ..colorspace = video_colorspace.VIDEO_CS_DEFAULT;

    int rv = _lib.obs_reset_video(ovi);
    calloc.free(ovi);

    var msg;
    switch (rv) {
      case OBS_VIDEO_SUCCESS:
        msg = 'success';
        break;
      case OBS_VIDEO_FAIL:
        msg = 'fail';
        break;
      case OBS_VIDEO_NOT_SUPPORTED:
        msg = 'not supported';
        break;
      case OBS_VIDEO_INVALID_PARAM:
        msg = 'invalid parameter';
        break;
      case OBS_VIDEO_CURRENTLY_ACTIVE:
        msg = 'currently active';
        break;
      case OBS_VIDEO_MODULE_NOT_FOUND:
        msg = 'module not found';
        break;
      default:
        msg = 'fail';
        break;
    }

    if (rv != OBS_VIDEO_SUCCESS) {
      print("dive_obslib: Couldn't initialize video: $msg ($rv)");
      return false;
    }
    return true;
  }

  void logVideoActive() {
    final msg = _lib.obs_video_active() == 1 ? 'OBS video(active)' : 'OBS video(not active)';
    debugPrintStack(label: msg, maxFrames: 3);
  }

  bool resetAudio() {
    final ai = calloc<obs_audio_info>();
    ai.ref
      ..samples_per_sec = 48000
      ..speakers = speaker_layout.SPEAKERS_STEREO;
    int rv = _lib.obs_reset_audio(ai);
    calloc.free(ai);
    if (rv == 0) {
      print("Couldn't initialize audio: $rv");
      return false;
    }

    return true;
  }

  /// Gets the current video settings, returns null if no video.
  Map<String, dynamic>? videoGetInfo() {
    Map<String, dynamic>? info;
    final ovi = calloc<obs_video_info>();
    final rv = _lib.obs_get_video_info(ovi);
    if (rv == 1) {
      info = {
        'graphics_module': StringExtensions.fromInt8(ovi.ref.graphics_module),
        'fps_num': ovi.ref.fps_num,
        'fps_den': ovi.ref.fps_den,
        'base_width': ovi.ref.base_width,
        'base_height': ovi.ref.base_height,
        'output_width': ovi.ref.output_width,
        'output_height': ovi.ref.output_height,
        'output_format': ovi.ref.output_format,
        'adapter': ovi.ref.adapter,
        'gpu_conversion': ovi.ref.gpu_conversion == 1,
        'colorspace': ovi.ref.colorspace,
        'range': ovi.ref.range,
        'scale_type': ovi.ref.scale_type,
      };
    }
    calloc.free(ovi);
    return info;
  }

  // Shutdown OBS.
  void shutdown() {
    _lib.obs_shutdown();
    final totalMemLeaks = _lib.bnum_allocs();
    print('Shutdown: number OBS of memory leaks: $totalMemLeaks');
  }

  DivePointer? createScene(String trackingUUID, String sceneName) {
    _assertInitialized();

    final scene = _lib.obs_scene_create(sceneName.int8());
    StringExtensions.freeInt8s();
    if (scene == ffi.nullptr) {
      print("Couldn't create scene: $sceneName");
      return null;
    }

    final diveScene = DivePointer(trackingUUID, scene);

    if (_isFirstScene) {
      _isFirstScene = false;

      changeScene(diveScene);
    }

    return diveScene;
  }

  /// Set the scene as the primary draw source.
  void changeScene(DivePointer scene) {
    final channel = 0;
    _lib.obs_set_output_source(channel, _lib.obs_scene_get_source(scene.pointer));
  }

  void deleteScene(DivePointer scene) {
    final channel = 0;
    _lib.obs_set_output_source(channel, ffi.nullptr);
    _lib.obs_scene_release(scene.pointer);
  }

  DivePointer? createImageSource(String sourceUuid, String file) {
    final settings = _lib.obs_data_create();
    _lib.obs_data_set_string(settings, "file".int8(), file.int8());

    return _createSourceInternal(sourceUuid, "image_source", "image", settings);
  }

  /// Load media source
  DivePointer? createMediaSource(
      {required String sourceUuid, required String name, required DiveObslibData settings}) {
    return _createSourceInternal(sourceUuid, "ffmpeg_source", name, settings.pointer);
  }

  /// Use this convenience method to create a data object for settings.
  DiveObslibData createData() => DiveObslibData();

  DivePointer? createVideoSource(String sourceUuid, String deviceName, String deviceUid) {
    final data = DiveObslibData();
    data.setString("device_name", deviceName);
    data.setString("device", deviceUid);

    // TODO: creating a video source breaks the Flutter connection to the device.
    final pointer = _createSourceInternal(sourceUuid, "av_capture_input", "camera", data.pointer);
    data.dispose();
    return pointer;
  }

  /// Creates a source of the specified type with the specified settings.
  DivePointer? createSource({
    required String sourceUuid,
    required String inputTypeId,
    required String name,
    required DiveObslibData settings,
  }) =>
      _createSourceInternal(sourceUuid, inputTypeId, name, settings.pointer);

  // static const except = -1;

  /// If you see this message: The method 'FfiTrampoline' was called on null
  /// make sure to use nullptr instead of null.
  /// https://github.com/dart-lang/sdk/issues/39804#

  DivePointer? _createSourceInternal(
    String sourceUuid, // TODO: do we really need this sourceUuid?
    String sourceId,
    String name,
    ffi.Pointer<obs_data> settings,
  ) {
    final source = _lib.obs_source_create(sourceId.int8(), name.int8(), settings, ffi.nullptr);
    StringExtensions.freeInt8s();
    if (source == ffi.nullptr) {
      debugPrint("_createSourceInternal: Could not create source");
      return null;
    }

    return DivePointer(sourceUuid, source);
  }

  /// Releases a reference to a source.  When the last reference is released, the source is destroyed.
  void releaseSource(DivePointer source) {
    _lib.obs_source_remove(source.pointer);
    _lib.obs_source_release(source.pointer);
  }

  /// Gets the current async video frame.
  void sourceGetFrame(DivePointer source) {
    ffi.Pointer<obs_source_frame> frame = _lib.obs_source_get_frame(source.pointer);
    if (frame == ffi.nullptr) {
      debugPrint('sourceGetFrame: could not get a frame');
    } else {
      debugPrint('sourceGetFrame $frame');
    }
  }

  /// Add an existing source to an existing scene, and return sceneitem id.
  DivePointerSceneItem sceneAddSource(DivePointer scene, DivePointer source) {
    final item = _lib.obs_scene_add(scene.pointer, source.pointer);
    return DivePointerSceneItem(item);
  }

  bool sceneItemIsVisible(DivePointerSceneItem item) {
    final rv = _lib.obs_sceneitem_visible(item.pointer);
    return rv == 1;
  }

  bool sceneItemSetVisible(DivePointerSceneItem item, bool visible) {
    final rv = _lib.obs_sceneitem_set_visible(item.pointer, visible ? 1 : 0);
    return rv == 1;
  }

  void sceneItemSetOrder(DivePointerSceneItem item, int movement) {
    _lib.obs_sceneitem_set_order(item.pointer, movement);
  }

  /// Remove an existing scene item from a scene.
  void sceneItemRemove(DivePointerSceneItem item) {
    _lib.obs_sceneitem_remove(item.pointer);
  }

  /// Get the transform info for a scene item.
  /// TODO: this does not work because of FFI struct issues.
  Map sceneItemGetInfo(DivePointerSceneItem item) {
    // final item = _lib.obs_scene_find_sceneitem_by_id(scene.pointer, itemId);
    // obs_transform_info info;
    // _lib.obs_sceneitem_get_info(item, info);
    // TODO: finish this
    return {}; // _convert_transform_info_to_dict(info);
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

  /// Recording Controls

  /// Create the recording output at the specified [path],
  /// Returns a pointer or null.
  DivePointerOutput? recordingOutputCreate({
    required String path,
    required String outputName,
    String outputType = 'ffmpeg_muxer',
  }) {
    final recordingOutput =
        _lib.obs_output_create(outputType.int8(), outputName.int8(), ffi.nullptr, ffi.nullptr);
    if (recordingOutput == ffi.nullptr) {
      print("creation of recording output type $outputType failed");
      return null;
    }

    final vencoder = _lib.obs_video_encoder_create(
        "obs_x264".int8(), "simple_h264_stream".int8(), ffi.nullptr, ffi.nullptr);
    final aencoder =
        _lib.obs_audio_encoder_create("ffmpeg_aac".int8(), "test_aac".int8(), ffi.nullptr, 0, ffi.nullptr);
    _lib.obs_encoder_set_video(vencoder, _lib.obs_get_video());
    _lib.obs_encoder_set_audio(aencoder, _lib.obs_get_audio());
    _lib.obs_output_set_video_encoder(recordingOutput, vencoder);
    _lib.obs_output_set_audio_encoder(recordingOutput, aencoder, 0);

    // _lib.obs_encoder_release(vencoder);
    // _lib.obs_encoder_release(aencoder);

    final outputSettings = DiveObslibData();
    outputSettings.setString("path", path);
    outputSettings.setString("muxer_settings", "");
    outputSettings.setString("format_name", "avi");
    outputSettings.setString("video_encoder", "utvideo");
    outputSettings.setString("audio_encoder", "pcm_s16le");
    _lib.obs_output_update(recordingOutput, outputSettings.pointer);
    outputSettings.dispose();

    final aMixes = 1;
    _lib.obs_output_set_mixers(recordingOutput, aMixes);

    return DivePointerOutput(recordingOutput);
  }

  /// Stream Controls

  /// Create the stream output.
  /// Returns a pointer or null.
  DivePointerOutput? streamOutputCreate({
    required String serviceName,
    required String serviceUrl,
    required String serviceKey,
    String serviceId = 'rtmp_common',
    String outputType = 'rtmp_output',
  }) {
    final serviceSettings = DiveObslibData();
    serviceSettings.setString("service", serviceName);
    serviceSettings.setString("server", serviceUrl);
    serviceSettings.setString("key", serviceKey);

    final serviceObj =
        _lib.obs_service_create(serviceId.int8(), serviceName.int8(), serviceSettings.pointer, ffi.nullptr);
    serviceSettings.dispose();

    final streamOutput =
        _lib.obs_output_create(outputType.int8(), serviceName.int8(), ffi.nullptr, ffi.nullptr);
    if (streamOutput == ffi.nullptr) {
      print("creation of stream output type $outputType failed");
      return null;
    }

    final vencoder = _lib.obs_video_encoder_create(
        "obs_x264".int8(), "simple_h264_stream".int8(), ffi.nullptr, ffi.nullptr);
    final aencoder =
        _lib.obs_audio_encoder_create("ffmpeg_aac".int8(), "test_aac".int8(), ffi.nullptr, 0, ffi.nullptr);
    _lib.obs_encoder_set_video(vencoder, _lib.obs_get_video());
    _lib.obs_encoder_set_audio(aencoder, _lib.obs_get_audio());
    _lib.obs_output_set_video_encoder(streamOutput, vencoder);
    _lib.obs_output_set_audio_encoder(streamOutput, aencoder, 0);

    // _lib.obs_encoder_release(vencoder);
    // _lib.obs_encoder_release(aencoder);

    _lib.obs_output_set_service(streamOutput, serviceObj);

    final outputSettings = DiveObslibData();
    outputSettings.setString("bind_ip", "default");
    outputSettings.setBool("new_socket_loop_enabled", false);
    outputSettings.setBool("low_latency_mode_enabled", false);
    outputSettings.setBool("dyn_bitrate", false);
    _lib.obs_output_update(streamOutput, outputSettings.pointer);
    outputSettings.dispose();

    return DivePointerOutput(streamOutput);
  }

  /// Release the output.
  bool outputRelease(DivePointerOutput output) {
    _lib.obs_output_release(output.pointer);
    return true;
  }

  /// Start the output.
  bool outputStart(DivePointerOutput output) {
    final rv = _lib.obs_output_start(output.pointer);
    if (rv != 1) {
      print("streamOutputStart: output not started");
    }
    return rv == 1;
  }

  /// Stop the output.
  void outputStop(DivePointerOutput output) {
    _lib.obs_output_stop(output.pointer);
  }

  /// Get the list of the streaming service names.
  /// When [commonNamesOnly] is true (default) it returns only the common services, and when
  /// false it returns all services.
  /// Returns a list of service names.
  List<String> streamOutputGetServiceNames({String serviceId = "rtmp_common", bool commonNamesOnly = true}) {
    var names = <String>[];
    final props = _lib.obs_get_service_properties(serviceId.int8());

    final settings = DiveObslibData();
    settings.setBool("show_all", !commonNamesOnly);
    final prop = _lib.obs_properties_get(props, "show_all".int8());
    settings.modify(prop);
    settings.dispose();

    final services = _lib.obs_properties_get(props, "service".int8());
    final servicesCount = _lib.obs_property_list_item_count(services);
    for (var index = 0; index < servicesCount; index++) {
      final name = _lib.obs_property_list_item_string(services, index);
      final nameStr = StringExtensions.fromInt8(name);
      if (nameStr != null && nameStr.isNotEmpty) {
        names.add(nameStr);
      }
    }
    _lib.obs_properties_destroy(props);
    StringExtensions.freeInt8s();

    names.sort();
    return names;
  }

  /// Get the list of the servers for a streaming service.
  /// Returns a map with key as name and value as server url.
  Map<String, String> streamOutputGetServiceServers(
      {String serviceId = "rtmp_common", required String serviceName}) {
    var names = Map<String, String>();
    final props = _lib.obs_get_service_properties(serviceId.int8());

    final settings = DiveObslibData();
    settings.setString("service", serviceName);
    final prop = _lib.obs_properties_get(props, "service".int8());
    settings.modify(prop);
    settings.dispose();

    final services = _lib.obs_properties_get(props, "server".int8());
    final servicesCount = _lib.obs_property_list_item_count(services);
    for (var index = 0; index < servicesCount; index++) {
      final name = _lib.obs_property_list_item_name(services, index).string;
      final server = _lib.obs_property_list_item_string(services, index).string;
      if (name != null && name.isNotEmpty && server != null && server.isNotEmpty) names[name] = server;
    }
    _lib.obs_properties_destroy(props);
    StringExtensions.freeInt8s();

    return names;
  }

  /// Get the output state: 0 (stopped), 1 (active), 2 (paused), 3 (reconnecting), 4 (failed)
  int outputGetState(DivePointerOutput output) {
    final active = _lib.obs_output_active(output.pointer);
    final paused = _lib.obs_output_paused(output.pointer);
    final reconnecting = _lib.obs_output_reconnecting(output.pointer);
    final error = _lib.obs_output_get_last_error(output.pointer);
    final errorMsg = error.string;

    int state = 0;
    if (reconnecting == 1)
      state = 3;
    else if (active == 1)
      state = 1;
    else if (paused == 1)
      state = 2;
    else if (errorMsg != null && errorMsg.isNotEmpty) {
      state = 4;
    }
    ;

    return state;
  }

  /// Media Controls
  /// TODO: implement signals from media source: obs_source_get_signal_handler

  /// Media control: play_pause
  void mediaSourcePlayPause(DivePointer source, bool pause) {
    _lib.obs_source_media_play_pause(source.pointer, pause ? 1 : 0);
  }

  /// Media control: restart
  void mediaSourceRestart(DivePointer source) {
    _lib.obs_source_media_restart(source.pointer);
  }

  /// Media control: stop
  void mediaSourceStop(DivePointer source) {
    _lib.obs_source_media_stop(source.pointer);
  }

  /// Media control: get time
  int mediaSourceGetDuration(DivePointer source) {
    return _lib.obs_source_media_get_duration(source.pointer);
  }

  /// Media control: get time
  int mediaSourceGetTime(DivePointer source) {
    return _lib.obs_source_media_get_time(source.pointer);
  }

  /// Media control: set time
  void mediaSourceSetTime(DivePointer source, int ms) {
    _lib.obs_source_media_set_time(source.pointer, ms);
  }

  /// Media control: get state
  int mediaSourceGetState(DivePointer source) {
    return _lib.obs_source_media_get_state(source.pointer);
  }

  /// Create a volume meter.
  DivePointer volumeMeterCreate({
    int faderType = obs_fader_type.OBS_FADER_LOG,
  }) {
    final volmeter = _lib.obs_volmeter_create(faderType);
    return DivePointer(null, volmeter);
  }

  /// Attache a source to a volume meter.
  bool volumeMeterAttachSource(DivePointer volumeMeter, DivePointer source) {
    final rv = _lib.obs_volmeter_attach_source(volumeMeter.pointer, source.pointer);
    return rv == 1;
  }

  /// Set the peak meter type for the volume meter.
  void volumeMeterSetPeakMeterType(DivePointer volumeMeter,
      {int meterType = obs_peak_meter_type.SAMPLE_PEAK_METER}) {
    _lib.obs_volmeter_set_peak_meter_type(volumeMeter.pointer, meterType);
  }

  /// Get the number of channels which are configured for this source.
  int volumeMeterGetNumberChannels(DivePointer volumeMeter) {
    return _lib.obs_volmeter_get_nr_channels(volumeMeter.pointer);
  }

  /// Destroy a volume meter.
  void volumeMeterDestroy(DivePointer volumeMeter) {
    _lib.obs_volmeter_destroy(volumeMeter.pointer);
  }

  /// Get a list of input types.
  /// Returns array of dictionaries with keys `id` and `name`.
  List<Map<String, String>> get inputTypes {
    int idx = 0;
    final List<Map<String, String>> list = [];

    ffi.Pointer<ffi.Pointer<ffi.Int8>> typeId = calloc();
    ffi.Pointer<ffi.Pointer<ffi.Int8>> unversionedTypeId = calloc();

    while (_lib.obs_enum_input_types2(idx++, typeId, unversionedTypeId) != 0) {
      final name = _lib.obs_source_get_display_name(typeId.value);
      final caps = _lib.obs_get_source_output_flags(typeId.value);

      if ((caps & OBS_SOURCE_CAP_DISABLED) != 0) continue;

      bool deprecated = (caps & OBS_SOURCE_DEPRECATED) != 0;
      if (deprecated) {
      } else {}

      list.add({
        "id": StringExtensions.fromInt8(unversionedTypeId.value) ?? '',
        "name": StringExtensions.fromInt8(name) ?? ''
      });
    }
    calloc.free(typeId);
    calloc.free(unversionedTypeId);

    list.add({"id": "scene", "name": "Scene"});
    return list;
  }

  /// Get a list of inputs from input type.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    final List<Map<String, String>> list = [];

    final sourceProps = _lib.obs_get_source_properties(inputTypeId.int8());

    if (sourceProps != ffi.nullptr) {
      ffi.Pointer<ffi.Pointer<obs_property>> propertyOut = calloc();

      var property = _lib.obs_properties_first(sourceProps);
      while (property != ffi.nullptr) {
        final type = _lib.obs_property_get_type(property);
        if (type == obs_property_type.OBS_PROPERTY_LIST) {
          final count = _lib.obs_property_list_item_count(property);
          for (int index = 0; index < count; index++) {
            final disabled = _lib.obs_property_list_item_disabled(property, index);
            final name = _lib.obs_property_list_item_name(property, index).string;
            final uid = _lib.obs_property_list_item_string(property, index).string;
            if (disabled == 0 && name != null && uid != null && name.isNotEmpty && uid.isNotEmpty) {
              list.add({"id": uid, "name": name, "type_id": inputTypeId});
            }
          }
        }
        propertyOut.value = property;
        final rv = _lib.obs_property_next(propertyOut);
        property = rv == 1 ? propertyOut.value : ffi.nullptr;
      }
      _lib.obs_properties_destroy(sourceProps);
      calloc.free(propertyOut);
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

  /// Get a list of the audio monitoring devices.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> audioMonitoringDevices() {
    final List<Map<String, String>> list = [];

    final cb = ffi.Pointer.fromFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Int8>,
          ffi.Pointer<ffi.Int8>,
        )>(_audioCallback, 0);
    _lib.obs_enum_audio_monitoring_devices(cb, list as dynamic);

    list.add({'id': 'default', 'name': 'Default'});
    return list;
  }

  /// Callback for [audioMonitoringDevices].
  /// fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart
  /// functions from native code. Closures and tear-offs are not supported because they can capture context.
  static int _audioCallback(
      ffi.Pointer<ffi.Void> param, ffi.Pointer<ffi.Int8> name, ffi.Pointer<ffi.Int8> id) {
    final list = param as List;
    list.add({'id': StringExtensions.fromInt8(id), 'name': StringExtensions.fromInt8(name)});
    print('audio monitoring device: name=$name, id=$id');
    return 1;
  }

  List<Map<String, String>> sourceTypes() {
    int idx = 0;
    final List<Map<String, String>> list = [];

    ffi.Pointer<ffi.Pointer<ffi.Int8>> id = calloc();
    while (_lib.obs_enum_source_types(idx++, id) != 0) {
      final sourceType = _lib.obs_source_get_display_name(id.value).string;
      if (id.value.string != null && sourceType != null) {
        list.add({'id': id.value.string!, 'name': sourceType});
      }
    }
    calloc.free(id);
    return list;
  }

  /// Print out a list of active sources.
  void sources() {
    final cb = ffi.Pointer.fromFunction<ffi.Uint8 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<obs_source>)>(
        _sourcesCallback, 0);
    _lib.obs_enum_sources(cb, ffi.nullptr);
  }

  /// Callback for [sources].
  /// fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart
  /// functions from native code. Closures and tear-offs are not supported because they can capture context.
  static int _sourcesCallback(ffi.Pointer<ffi.Void> data, ffi.Pointer<obs_source> source) {
    print("source=$source");
    return 1;
  }

  bool audioSetDefaultMonitoringDevice() {
    return audioSetMonitoringDevice('Default', 'default');
  }

  /// Set the audio monitoring device.
  bool audioSetMonitoringDevice(String name, String id) {
    print('audioSetMonitoringDevice: name=$name');

    final rv = _lib.obs_set_audio_monitoring_device(name.int8(), id.int8());
    StringExtensions.freeInt8s();
    return rv == 1;
  }

  /// Set the monitoring type for a source.
  void sourceSetMonitoringType(
    DivePointer source, {
    int type = obs_monitoring_type.OBS_MONITORING_TYPE_MONITOR_AND_OUTPUT,
    bool muted = false,
  }) {
    _lib.obs_source_set_monitoring_type(source.pointer, type);

    // Mute/Unmute the audio source
    _lib.obs_source_set_muted(source.pointer, muted ? 1 : 0);
  }

  /// Get the monitoring type for a source.
  int sourceGetMonitoringType(DivePointer source) => _lib.obs_source_get_monitoring_type(source.pointer);

  /// Set the volume level (dB) for a source.
  void sourceSetVolume(DivePointer source, double levelDb) {
    _lib.obs_source_set_volume(source.pointer, fromDb(levelDb));
  }

  /// Get the volume level (dB) for a source.
  double sourceGetVolume(DivePointer source) {
    double level = _lib.obs_source_get_volume(source.pointer);
    return toDb(level);
  }

  /// Convert dB to value.
  double fromDb(double value) => _lib.obs_db_to_mul(value);

  /// Convert value to dB.
  double toDb(double value) => _lib.obs_mul_to_db(value);
}

/// A wrapper around [obs_data] and the [obs_data_*] functions.
/// Example:
///   void exampleUseData() {
///     final data = DiveObslibData();
///     data.setBool("is_local_file", true);
///     data.dispose();
///   }
class DiveObslibData {
  ffi.Pointer<obs_data> _data = _lib.obs_data_create();
  ffi.Pointer<obs_data> get pointer => _data;

  /// Release the underlying data.
  void dispose() {
    _lib.obs_data_release(_data);
    StringExtensions.freeInt8s();
  }

  void modify(ffi.Pointer<obs_property> prop) {
    _lib.obs_property_modified(prop, _data);
  }

  void setBool(String name, bool value) => _lib.obs_data_set_bool(_data, name.int8(), value ? 1 : 0);
  void setDouble(String name, double value) => _lib.obs_data_set_double(_data, name.int8(), value);
  void setInt(String name, int value) => _lib.obs_data_set_int(_data, name.int8(), value);
  void setString(String name, String value) => _lib.obs_data_set_string(_data, name.int8(), value.int8());
}
