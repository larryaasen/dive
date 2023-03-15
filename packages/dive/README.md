# Dive

Introducing Dive! A new Flutter toolkit for video recording and streaming.
A complete set of packages to build the next generation of Flutter media apps.

[![pub package](https://img.shields.io/pub/v/dive.svg)](https://pub.dev/packages/dive)
<a href="https://www.buymeacoffee.com/larryaasen">
  <img alt="Gift me a coffee" src="https://img.shields.io/badge/Donate-Gift%20Me%20A%20Coffee-yellow.svg">
</a>

## Introduction

Dive is a video recording and streaming toolkit built on top of Dart and
Flutter with native extensions on macOS. It is a group of Flutter packages for
building media apps. In the future, support for multiple
platforms will be added.

| Package         | Version | Description |
| -- | -- | -- |
| **dive**        | [![pub package](https://img.shields.io/pub/v/dive.svg)](https://pub.dev/packages/dive) | A Flutter package that provides video capabilities. |
| **dive_ui**     | [![pub package](https://img.shields.io/pub/v/dive_ui.svg)](https://pub.dev/packages/dive_ui) | A Flutter package for Dive containing Widgets for building Flutter apps for video recording and streaming. |
| **dive_obslib** | [![pub package](https://img.shields.io/pub/v/dive_obslib.svg)](https://pub.dev/packages/dive_obslib) | A Flutter plugin package for Dive that provides low level access to obslib using FFI. |

# Packages

## dive

The [dive](https://pub.dev/packages/dive) package is a Flutter package that provides basic services for
video playback, camera devices, audio, and streaming. This package relies
heavily on the dive_obslib package but remains platform indepenent.

## dive_ui

The [dive_ui](https://pub.dev/packages/dive_ui) package is a Flutter package containing Widgets to build video based
Flutter apps. This package relies heavily on the dive package but remains
platform indepenent.

This package contains many examples on using dive_ui widgets and dive
classes. The examples use the macos platform folder that contains a Podfile
that references the obslib CocoaPods library.

## dive_obslib

The [dive_obslib](https://pub.dev/packages/dive_obslib) package is a Flutter plugin that provides low level access
to obslib. This package 
contains platform-specific implementations with native extensions for macOS, and
other platforms in the future.

dive_obslib is powered by obslib, a CocoaPods library built from the core of OBS Studio.
It utilizes all of the underlying features of OBS Studio excluding the UI code.
It includes inputs, sources, outputs, encoders, services, and more.

dive_obslib contains the DiveObsLibPlugin and the dive_obslib CocoaPods library. The
dive_obslib pod has a dependency on the obslib CocoaPods library.

# Dependencies

## obslib CocoaPods library

The [obslib](https://github.com/larryaasen/obslib-framework) CocoaPods library is a wrapper around the obslib Framework that can
be consumed by the DiveApp macOS platform Podfile.

## obslib Framework

The [obslib framework (obslib-framework)](https://github.com/larryaasen/obslib-framework) is the core of OBS Studio,
and is the non-UI code and resources compiled into a reusable framework. The framework
is built by an Xcode project.

The framework folder contains an example macOS application that consumes the
obslib framework without using CocoaPods and is used to test the framework.

# Getting Started
