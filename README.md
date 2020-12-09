# Dive

Dive is a video recording and streaming platform built on top of Dart and
Flutter with native extensions on multiple platforms.

## Introduction

DiveCore - a Flutter plugin package that provides video capabilities.

DiveUI - a Flutter plugin package that provides Widgets for Flutter apps using DiveCore.

DiveApp - a Flutter app for video recording and streaming.

## DiveCore

The DiveCore package is a Flutter plugin that provides low level services for
video playback, camera devices, live streaming, and audio. This package
contains platform-specific implementations with native extensions for Android,
iOS, and macOS.

DiveCore is powered by obslib, a CocoaPods library built from the core of OBS Studio.
It utilizes all of the underlying features of OBS Studio excluding the UI code.
It includes inputs, sources, outputs, encoders, services, and more.

DiveCore contains the DiveCorePlugin and the dive_core CocoaPods library. The
dive_core pod has a dependency on the obslib CocoaPods library.

## DiveUI

The DiveUI package is a Flutter package containing Widgets to build video based
Flutter apps. This package relies heavily on the DiveCore package but remains
platform indepenent.

## DiveApp

The DiveApp app is a Flutter app for video live streaming and recording that uses Wigets from
the DiveUI package. This app has code that is platform independent, but will
only run on the platforms supported by DiveCore, which for now is
Android, iOS, and macOS.

The pubspec.yaml file has dependencies for dive_core and dive_ui.

The macOS platform folder contains a Podfile that references the obslib
CocoaPods library.

## obslib CocoaPods library

The obslib CocoaPods library is a wrapper around the obslib Framework that can
be consumed by the DiveApp macOS platform Podfile.

## obslib Framework

The obslib framework (obslib-framework) is the core of OBS Studio,
and is the non-UI code and resources compiled into a reusable framework. The framework
is built by an Xcode project.

The framework folder contains an example macOS application that consumes the
obslib framework without using CocoaPods and is used to test the framework.

### Components of the framework

* header files
* data files
* libraries
* plugins

Libraries:
* libobs-opengl.so
* libobsglad.0.dylib
* libobs-frontend-api.dylib
* libobs-scripting.dylib
* libobs.0.dylib
* libavformat.58.dylib
* libpostproc.55.dylib
* libavfilter.7.dylib
* libjansson.4.dylib
* libavcodec.58.dylib
* libavutil.56.dylib
* libswscale.5.dylib
* libavdevice.58.dylib
* libx264.160.dylib
* libswresample.3.dylib
* libmbedx509.2.16.5.dylib
* libfreetype.6.dylib
* libmbedx509.2.16.5.dylib
* librnnoise.0.dylib
* liblaujit-5.1.2.1.0.dylib
* libmbedcrypto.2.16.5.dylib

Plugins:
* mac-capture.so
* obs-ffmpeg.so
* linux-jack.so
* obs-libfdk.so
* obs-x264.so
* obs-transitions.so
* obs-filters.so
* vlc-video.so
* obs-browser.so
* obs-outputs.so
* mac-syphon.so
* text-freetype2.so
* mac-vth264.so
* image-source.so
* coreaudio-encoder.so
* obs-vst.so
* rtmp-services.so
* mac-avcapture.so
* mac-decklink.so

## Dive Folder Structure

```
dive
 |-- dive_app
 |-- dive_core
 |-- dive_ui
```

## Concepts

### Input Source

An input source is a camera, microphone, virtual camera, screen capture,
or NDI source.

### Sources

### channel

### output

### Encoders

### Services
