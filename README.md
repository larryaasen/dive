# Dive

Introducing Dive! A new Flutter toolkit for video recording and streaming.
A complete set of packages to build the next generation of Flutter media apps.

## Introduction

Dive is a video recording and streaming toolkit built on top of Dart and
Flutter with native extensions on macOS. It is a group of Flutter packages for
building media apps. In the future, support for multiple
platforms will be added.

**dive** - A Flutter package that provides video capabilities.

**dive_ui** - A Flutter package for Dive containing Widgets for building Flutter
apps for video recording and streaming.

**dive_obslib** - A Flutter plugin package for Dive that provides low level access
to obslib using FFI.

## dive

The dive package is a Flutter package that provides basic services for
video playback, camera devices, audio, and streaming. This package relies
heavily on the dive_obslib package but remains platform indepenent.

## dive_ui

The dive_ui package is a Flutter package containing Widgets to build video based
Flutter apps. This package relies heavily on the dive package but remains
platform indepenent.

This package contains many examples on using dive_ui widgets and dive
classes. The examples use the macOS platform folder that contains a Podfile
that references the obslib CocoaPods library.

## dive_obslib

The dive_obslib package is a Flutter plugin that provides low level access
to obslib. This package 
contains platform-specific implementations with native extensions for Android,
iOS, and macOS.

dive_obslib is powered by obslib, a CocoaPods library built from the core of OBS Studio.
It utilizes all of the underlying features of OBS Studio excluding the UI code.
It includes inputs, sources, outputs, encoders, services, and more.

dive_obslib contains the DiveObsLibPlugin and the dive_obslib CocoaPods library. The
dive_obslib pod has a dependency on the obslib CocoaPods library.

## obslib CocoaPods library

The obslib CocoaPods library is a wrapper around the obslib Framework that can
be consumed by the DiveApp macOS platform Podfile.

## obslib Framework

The obslib framework (obslib-framework) is the core of OBS Studio,
and is the non-UI code and resources compiled into a reusable framework. The framework
is built by an Xcode project.

The framework folder contains an example macOS application that consumes the
obslib framework without using CocoaPods and is used to test the framework.

### Components of the obslib framework

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
 |-- apps
   |-- dive_app
 |-- packages
   |-- dive
   |-- dive_obslib
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

# Class Diagram


FFI:
dive_core:[DiveScene] -> dive_obslib:[DiveObsBridge -> DiveObslibFFI.dart -> |FFI| -> obslib.framework]
dive_core:[TextureController] -> dive_obslib:[DivePlugin.dart |->| DiveObsLibPlugin.swift -> obslib.framework]

Plugin:
dive_core:[DiveScene] -> dive_obslib:[DivePlugin.dart |->| DiveObsLibPlugin.swift -> obslib.framework]
dive_core:[TextureController] -> dive_obslib:[DivePlugin.dart |->| DiveObsLibPlugin.swift -> obslib.framework]

Note: DiveObslib does not contain anything and is really nothing.

      FFI             Plugin
      ===             ======

dive_core [========================= no platform code]
   DiveScene         DiveScene
       |                 |
       V                 V
dive_obslib [========================= macos platform code]

 DiveObsBridge       DivePlugin
       |                 |
       V                 V
 DiveObslibFFI    DiveObsLibPlugin.swift
       |                 |
       V                 V
      FFI         dive_obs_bridge.mm
       |                 |
       V                 V
obslib.framework  obslib.framework

New:
            DiveScene
                |
                V
dive_obslib [========================= macos platform code]
             DiveObs
                |
       +--------+--------+
       |                 |
       V                 V
 DiveObslibFFI    DiveObsLibPlugin.swift
       |                 |
       V                 V
      FFI         dive_obs_bridge.mm
       |                 |
       V                 V
obslib.framework  obslib.framework
