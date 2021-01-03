# dive_obslib

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
* All code will be written in Dart instead of Objective-C and Swift.
* Avoids the difficulty of mapping C pointers to Dart objects.
* Might be easier to port DiveCore to Windows.
* Will not need three levels: bridge (C), plugin (Swift), channel wrapper (Dart).
* The Dive objects can call FFI methods instead of the channel wrapper.
* Generating Dart bindings from C header files: https://gist.github.com/mannprerak2/e4530e6566b35cb94f8f1b340970973a
* This article may be helpful. https://medium.com/flutter-community/integrating-c-library-in-a-flutter-app-using-dart-ffi-38a15e16bc14

Reasons not to use dart:ffi to wrap obslib:
* The dart:ffi feature is still in beta and may change considerably over time.
* Difficult to use which will slow down development.
* Cannot step through the obslib code, which can be done via bridge wrapper.
* Would FFI callbacks work?
* Some unknowns - What parts of obslib would not work via FFI?
* FFI still seems too new to invest in it right now.

Completed FFI tasks:
* experimented calling obs_startup and a few other functions which worked well.