# dive_core_example

Demonstrates how to use the dive plugin.

## Example 1 - Streaming

This example shows how to use dive_core and dive_obslib to create a non-UI
app that will stream to Twitch.
* Use `DiveCoreElements` to track the scene, audio source, and video source.
* Create a scene (`DiveScene`).
* Create a `DiveAudioSource` for the main audio.
* Create a video source (`DiveVideoSource`) for the last video input (`DiveInputs.video()`).
* Create the streaming output `DiveOutput`.
* Start streaming to Twitch or YouTube.
* Wait 30 seconds, and then stop the stream.

## Running the app
Flutter cannot run apps from the Flutter command, so it needs to be run from Xcode.

First, run this from the command line to configure the app for running:
```
flutter run lib/main.dart --no-sound-null-safety
```
Then, open the workspace and run the app from Xcode.

After it starts running in Xcode, you can attach Flutter to the app with this,
replacing the URL with the one displayed in the Xcode console:
```
flutter attach --no-sound-null-safety --target=lib/main.dart --debug-uri http://127.0.0.1:59193/6jti2fp4_kk=/
```

### Output
This is output from the example app when streaming to Twitch.
```
2022-03-13 19:47:50.994849-0400 dive_core_example[1138:12399572] Metal API Validation Enabled
DiveObsLibPlugin registered.
2022-03-13 19:47:51.053620-0400 dive_core_example[1138:12399572] [] [0x7fc090012a20] CVCGDisplayLink::setCurrentDisplay: 69734406
2022-03-13 19:47:51.055134-0400 dive_core_example[1138:12399572] [] [0x7fc090012a00] CVDisplayLinkCreateWithCGDisplays count: 1 [displayID[0]: 0x4281006] [CVCGDisplayLink: 0x7fc090012a20]
2022-03-13 19:47:51.055213-0400 dive_core_example[1138:12399572] [] [0x7fc090012a20] CVCGDisplayLink::finalize
2022-03-13 19:47:51.055252-0400 dive_core_example[1138:12399572] [] [0x7fc090012a20] CVDisplayLink::finalize
flutter: Observatory listening on http://127.0.0.1:59193/6jti2fp4_kk=/
flutter: libobs library loaded: DynamicLibrary: handle=0xfffffffffffffffe
info: CPU Name: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz
info: CPU Speed: 2200MHz
info: Physical Cores: 6, Logical Cores: 12
info: Physical Memory: 16384MB Total
info: OS Name: Mac OS X
info: OS Version: Version 12.2.1 (Build 21D62)
info: Kernel Version: 21.3.0
2022-03-13 19:47:51.482097-0400 dive_core_example[1138:12399572] [default] 0x100c08eff: TCC deny IOHIDDeviceOpen
2022-03-13 19:47:51.482368-0400 dive_core_example[1138:12399572] [default] 0x100e23d39: TCC deny IOHIDDeviceOpen
2022-03-13 19:47:51.482578-0400 dive_core_example[1138:12399572] [default] 0x100e23d03: TCC deny IOHIDDeviceOpen
2022-03-13 19:47:51.482647-0400 dive_core_example[1138:12399572] [default] 0x100c08eff: TCC deny IOHIDDeviceOpen
error: hotkeys-cocoa: Getting keyboard keys failed
2022-03-13 19:47:51.482691-0400 dive_core_example[1138:12399572] [default] 0x100e23d39: TCC deny IOHIDDeviceOpen
error: hotkeys-cocoa: Getting keyboard keys failed
2022-03-13 19:47:51.482723-0400 dive_core_example[1138:12399572] [default] 0x100e23d03: TCC deny IOHIDDeviceOpen
error: hotkeys-cocoa: Getting keyboard keys failed
info: hotkeys-cocoa: Using layout 'com.apple.keylayout.US'
flutter: dive_obslib: load_all_modules
warning: Failed to load 'en' text for module: 'coreaudio-encoder.so'
warning: Failed to load 'en' text for module: 'image-source.so'
warning: Failed to load 'en' text for module: 'mac-avcapture.so'
2022-03-13 19:47:51.873747-0400 dive_core_example[1138:12400275] [plugin] AddInstanceForFactory: No factory registered for id <CFUUID 0x6000007938c0> 30010C1C-93BF-11D8-8B5B-000A95AF9C6A
2022-03-13 19:47:52.282791-0400 dive_core_example[1138:12400275] [plugin] AddInstanceForFactory: No factory registered for id <CFUUID 0x6000007938c0> 30010C1C-93BF-11D8-8B5B-000A95AF9C6A
warning: Failed to load 'en' text for module: 'mac-capture.so'
warning: Failed to load 'en' text for module: 'mac-decklink.so'
warning: A DeckLink iterator could not be created.  The DeckLink drivers may not be installed
info: No blackmagic support
warning: Failed to load 'en' text for module: 'mac-syphon.so'
error: os_dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/mac-virtualcam.so->/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/mac-virtualcam.so): dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/mac-virtualcam.so, 0x0101): Library not loaded: /tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets
  Referenced from: /Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/mac-virtualcam.so
  Reason: tried: '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/System/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file)

warning: Module '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/mac-virtualcam.so' not loaded
warning: Failed to load 'en' text for module: 'mac-vth264.so'
warning: obs_register_encoder: Encoder id 'vt_h264_hw' already exists!  Duplicate library?
info: [VideoToolbox encoder]: Adding VideoToolbox H264 encoders
error: os_dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-browser.so->/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-browser.so): dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-browser.so, 0x0101): Library not loaded: /tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets
  Referenced from: /Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-browser.so
  Reason: tried: '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/System/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file)

warning: Module '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-browser.so' not loaded
warning: Failed to load 'en' text for module: 'obs-ffmpeg.so'
warning: Failed to load 'en' text for module: 'obs-filters.so'
warning: Failed to load 'en' text for module: 'obs-outputs.so'
warning: Failed to load 'en' text for module: 'obs-transitions.so'
error: os_dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-vst.so->/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-vst.so): dlopen(/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-vst.so, 0x0101): Library not loaded: /tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets
  Referenced from: /Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-vst.so
  Reason: tried: '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/tmp/obsdeps/lib/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file), '/System/Library/Frameworks/QtWidgets.framework/Versions/5/QtWidgets' (no such file)

warning: Module '/Users/larry/Library/Developer/Xcode/DerivedData/Runner-bffqpvjkxmyffpeashgpjqiyrrvq/Build/Products/Debug/dive_core_example.app/Contents/PlugIns/obs-vst.so' not loaded
warning: Failed to load 'en' text for module: 'obs-x264.so'
warning: Failed to load 'en' text for module: 'rtmp-services.so'
warning: Failed to load 'en' text for module: 'text-freetype2.so'
warning: Failed to load 'en' text for module: 'vlc-video.so'
info: VLC found, VLC video source enabled
flutter: dive_obslib: post_load_modules
info: ---------------------------------
info: Initializing OpenGL...
info: Loading up OpenGL on adapter ATI Technologies Inc. AMD Radeon Pro 555X OpenGL Engine
info: OpenGL loaded successfully, version 4.1 ATI-4.7.103, shading language 4.10
info: ---------------------------------
info: video settings reset:
	base resolution:   1280x720
	output resolution: 1280x720
	downscale filter:  Disabled
	fps:               30000/1001
	format:            RGBA
	YUV mode:          None
info: ---------------------------------
info: audio settings reset:
	samples per sec: 48000
	speakers:        2
flutter: DiveAudioSource.create: device_id=default
2022-03-13 19:47:54.471738-0400 dive_core_example[1138:12400275] [plugin] AddInstanceForFactory: No factory registered for id <CFUUID 0x60000071d340> F8BB1C28-BAE8-11D6-9C31-00039315CD46
2022-03-13 19:47:54.523259-0400 dive_core_example[1138:12400275]  HALC_ShellDriverPlugIn::Open: opening the plug-in failed, Error: 2003329396 (what)
info: coreaudio: device 'HD Pro Webcam C920' initialized
info: adding 42 milliseconds of audio buffering, total audio buffering is now 42 milliseconds (source: main audio)

flutter: DiveInput name: FaceTime HD Camera (Built-in), id: 0x8020000005ac8514, typeId: av_capture_input
addFrameCapture: added texture source: 01ead7f0-a328-11ec-85e1-1b158e90c37d
flutter: Dive Example 1: Starting stream.
info: ---------------------------------
info: [x264 encoder: 'test_x264'] preset: veryfast
info: [x264 encoder: 'test_x264'] settings:
	rate_control: CBR
	bitrate:      2500
	buffer size:  2500
	crf:          0
	fps_num:      30000
	fps_den:      1001
	width:        1280
	height:       720
	keyint:       250

info: ---------------------------------
info: [FFmpeg aac encoder: 'test_aac'] bitrate: 128, channels: 2, channel_layout: 3

info: [rtmp stream: 'adv_stream'] Connecting to RTMP URL rtmp://live-iad05.twitch.tv/app/live_2...
flutter: Dive Example 1: Waiting 30 seconds.
info: camera: Selected device 'FaceTime HD Camera (Built-in)'
info: camera: Using preset 1280x720
obs_source_add_frame_callback: added
info: [rtmp stream: 'adv_stream'] Connection to rtmp://live-iad05.twitch.tv/app/live_2... successful
flutter: Dive Example 1: Stopping stream.
info: [rtmp stream: 'adv_stream'] User stopped the stream
info: Output 'adv_stream': stopping
info: Output 'adv_stream': Total frames output: 843
info: Output 'adv_stream': Total drawn frames: 899
[aac @ 0x7fc08e96e800] Qavg: 152.855
[aac @ 0x7fc08e96e800] 2 frames left in the queue on closing

```