# dive_obslib

A Flutter plugin package that provides low level access to obslib using FFI.

# Introduction

The dive_obslib package is part of the Dive video recording and streaming platform.
It provides the Dart wrapper
around [libobs](https://github.com/obsproject/obs-studio/tree/master/libobs)
from [OBS Studio](https://obsproject.com/) and
utilizes [Dart FFI](https://dart.dev/guides/libraries/c-interop) to call the native
C APIs in libobs.

## Building the obslib Framework

1: Starting by building OBS from source code. Here are the recommended build instructions: https://obsproject.com/wiki/Install-Instructions#macos-build-directions

    
    cd ~/obs-studio
    ./CI/full-build-macos.sh

Sometimes, the build will fail. Usually, it succeeds on the second attempt.


2: Next, build the macOS Framework.
- open obslib-framework.xcodeproj
- build


## OBS

input (camera) -> source -> scene -> channel -> final texture -> rtmp service -> -> encoder -> rtmp output
input (camera) -> source -> scene -> channel -> final texture -> rtmp service -> -> encoder -> rtmp output

source:
<- input (camera)
<- input (video file)

scene:
- [channels]

channel:
- source

source:
- input
- output stream

input:
- camera
- video file
- static image
- scene

YAML Config File:
- max_channels: 64

## OBS Video Format
MacBook Pro Camera: OBS video_format VIDEO_FORMAT_UYVY

## Using Dart dart:ffi
Using the Dart dart:ffi library to call the native C APIs in obslib.
https://dart.dev/guides/libraries/c-interop

This should be explored more.

Reasons to use dart:ffi to wrap obslib:
* Would make DiveCore more portable and have less platform code.
* Avoids the bridge duplication code.
* Avoids the asynchronous jump from the plugin to native using the platform channels.
* All code would be written in Dart instead of Objective-C and Swift.
* Avoids the difficulty of mapping C pointers to Dart objects.
* Might be easier to port DiveCore to Windows.
* Would not need three levels: bridge (C), plugin (Swift), channel wrapper (Dart).
* The Dive objects could call FFI methods instead of the channel wrapper.
* Generating Dart bindings from C header files: https://gist.github.com/mannprerak2/e4530e6566b35cb94f8f1b340970973a
* This article may be helpful. https://medium.com/flutter-community/integrating-c-library-in-a-flutter-app-using-dart-ffi-38a15e16bc14

Reasons not to use dart:ffi to wrap obslib:
* The dart:ffi feature is still in beta and may change considerably over time.
* Difficult to use which will slow down development.
* Cannot step through the obslib code, which can be done via bridge wrapper.
* Would FFI callbacks work?
* C structs inside C structs are not supported.
* When C code calls a callback from another thread (not the main Dart thread),
it is not supported: 
https://github.com/dart-lang/sdk/issues/40529#issuecomment-584530622
* Some unknowns - What parts of obslib would not work via FFI?
* FFI still seems too new to invest in it right now.
* Many of the functions in obs.h are inline, such as obs_source_frame_create, which is not supported in FFI.
* vec2 and vec3 do not convert using ffigen.
* Array members not supported in structs like audio_data and audio_output_data.
* Cannot call obs_startup via FFI because it must run on the main thread and FFI does not run on the main thread.

## Classes


DiveObsBridge - called by DiveCore to startup obslib using FFI.

## ffigen
Here are the messages of the latest ffigen 2.2.5 run using ffi 1.0.0.
```
$ make ffi
flutter pub run ffigen --config ffigen-config.yaml
Running in Directory: '/Users/larry/Projects/dive/dive_obslib'
Input Headers: [/Users/larry/Projects/obslib-framework/obslib.framework/Headers/obs.h]
[SEVERE] : Header /Users/larry/Projects/obslib-framework/obslib.framework/Headers/obs.h: Total errors/warnings: 37.
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:175:10: warning: '__int_least32_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:176:10: warning: '__uint_least32_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:177:10: warning: '__int_least16_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:178:10: warning: '__uint_least16_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:179:10: warning: '__int_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:180:10: warning: '__uint_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:208:10: warning: '__int_least16_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:209:10: warning: '__uint_least16_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:210:10: warning: '__int_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:211:10: warning: '__uint_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:227:10: warning: '__int_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:228:10: warning: '__uint_least8_t' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:365:11: warning: '__int32_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:366:11: warning: '__int16_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:367:11: warning: '__int8_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:403:11: warning: '__int16_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:404:11: warning: '__int8_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:424:11: warning: '__int8_c_suffix' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:558:10: warning: '__INT_LEAST32_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:559:10: warning: '__INT_LEAST32_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:560:10: warning: '__UINT_LEAST32_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:561:10: warning: '__INT_LEAST16_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:562:10: warning: '__INT_LEAST16_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:563:10: warning: '__UINT_LEAST16_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:564:10: warning: '__INT_LEAST8_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:565:10: warning: '__INT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:566:10: warning: '__UINT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:602:10: warning: '__INT_LEAST16_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:603:10: warning: '__INT_LEAST16_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:604:10: warning: '__UINT_LEAST16_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:605:10: warning: '__INT_LEAST8_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:606:10: warning: '__INT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:607:10: warning: '__UINT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:624:10: warning: '__INT_LEAST8_MIN' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:625:10: warning: '__INT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/12.0.0/include/stdint.h:626:10: warning: '__UINT_LEAST8_MAX' macro redefined [Lexical or Preprocessor Issue]
[SEVERE] :     /Users/larry/Projects/obslib-framework/obslib.framework/Headers/callback/../util/c99defs.h:43:10: fatal error: 'sys/types.h' file not found [Lexical or Preprocessor Issue]
[WARNING]: Skipped Function 'bzalloc', inline functions are not supported.
[WARNING]: Skipped Function 'bstrdup_n', inline functions are not supported.
[WARNING]: Skipped Function 'bwstrdup_n', inline functions are not supported.
[WARNING]: Skipped Function 'bstrdup', inline functions are not supported.
[WARNING]: Skipped Function 'bwstrdup', inline functions are not supported.
[WARNING]: Skipped Function 'profiler_snapshot_entry_times', function has unsupported return type or parameter type.
[WARNING]: Skipped Function 'profiler_snapshot_entry_times_between_calls', function has unsupported return type or parameter type.
[WARNING]: Skipped Function 'gs_vbdata_create', inline functions are not supported.
[WARNING]: Skipped Function 'gs_vbdata_destroy', inline functions are not supported.
[WARNING]: Skipped Function 'gs_get_format_bpp', inline functions are not supported.
[WARNING]: Skipped Function 'gs_is_compressed_format', inline functions are not supported.
[WARNING]: Skipped Function 'gs_is_srgb_format', inline functions are not supported.
[WARNING]: Skipped Function 'gs_get_total_levels', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_zero', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_set', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_copy', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_add', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_sub', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_mul', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_div', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_addf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_subf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_mulf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_divf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_neg', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_dot', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_len', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_dist', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_minf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_min', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_maxf', inline functions are not supported.
[WARNING]: Skipped Function 'vec2_max', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_zero', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_set', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_copy', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_add', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_sub', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_mul', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_div', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_addf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_subf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_mulf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_divf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_dot', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_cross', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_neg', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_len', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_dist', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_norm', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_close', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_min', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_minf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_max', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_maxf', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_abs', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_floor', inline functions are not supported.
[WARNING]: Skipped Function 'vec3_ceil', inline functions are not supported.
[WARNING]: Removed All Struct Members from: audio_data(audio_data), Array members not supported
[WARNING]: Removed All Struct Members from: audio_output_data(audio_output_data), Array members not supported
[WARNING]: Skipped Function 'get_audio_channels', inline functions are not supported.
[WARNING]: Skipped Function 'get_audio_bytes_per_channel', inline functions are not supported.
[WARNING]: Skipped Function 'is_audio_planar', inline functions are not supported.
[WARNING]: Skipped Function 'get_audio_planes', inline functions are not supported.
[WARNING]: Skipped Function 'get_audio_size', inline functions are not supported.
[WARNING]: Skipped Function 'audio_frames_to_ns', inline functions are not supported.
[WARNING]: Skipped Function 'ns_to_audio_frames', inline functions are not supported.
[WARNING]: Removed All Struct Members from: video_data(video_data), Array members not supported
[WARNING]: Skipped Function 'format_is_yuv', inline functions are not supported.
[WARNING]: Skipped Function 'get_video_format_name', inline functions are not supported.
[WARNING]: Skipped Function 'get_video_colorspace_name', inline functions are not supported.
[WARNING]: Skipped Function 'resolve_video_range', inline functions are not supported.
[WARNING]: Skipped Function 'get_video_range_name', inline functions are not supported.
[WARNING]: Skipped Function 'signal_handler_add_array', inline functions are not supported.
[WARNING]: Skipped Function 'obs_data_newref', inline functions are not supported.
[WARNING]: Removed All Struct Members from: obs_source_audio_mix(obs_source_audio_mix), Array members not supported
[WARNING]: Removed All Struct Members from: obs_source_frame(obs_source_frame), Array members not supported
[WARNING]: Removed All Struct Members from: obs_audio_data(obs_audio_data), Array members not supported
[WARNING]: Removed All Struct Members from: encoder_frame(encoder_frame), Array members not supported
[WARNING]: Skipped Function 'obs_key_combination_is_empty', inline functions are not supported.
[WARNING]: Removed All Struct Members from obs_transform_info(obs_transform_info), Incomplete Nested Struct member not supported.
[WARNING]: Removed All Struct Members from: obs_source_audio(obs_source_audio), Array members not supported
[WARNING]: Removed All Struct Members from: obs_source_frame2(obs_source_frame2), Array members not supported
[WARNING]: Skipped Function 'obs_source_frame_free', inline functions are not supported.
[WARNING]: Skipped Function 'obs_source_frame_create', inline functions are not supported.
[WARNING]: Skipped Function 'obs_source_frame_destroy', inline functions are not supported.
Finished, Bindings generated in /Users/larry/Projects/dive/dive_obslib/ffi_bindings.dart.txt
```
