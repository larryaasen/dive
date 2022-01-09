# Dive

Introducing Dive! A new Flutter toolkit for video recording and streaming.
A complete set of packages to build the next generation of Flutter media apps.

## Introduction

Dive is a video recording and streaming toolkit built on top of Dart and
Flutter with native extensions on macOS. It is a group of Flutter packages for
building media apps. In the future, support for multiple
platforms will be added.

**dive_core** - a Flutter package that provides video capabilities.

**dive_ui** - A Flutter package containing Widgets for building Flutter apps for
video recording and streaming.

(REMOVE) **dive_app** - a Flutter app for video recording and streaming.

## dive_core

The dive_core package is a Flutter package that provides basic services for
video playback, camera devices, audio, and streaming. This package relies on
other packages for low level platform and device support, but this package
remains platform indepenent.

## dive_ui

The dive_ui package is a Flutter package containing Widgets to build video based
Flutter apps. This package relies heavily on the dive_core package but remains
platform indepenent.

This package contains many examples on using dive_ui widgets and dive_core
classes. The examples only used a macOS platform folder.

## Dive Folder Structure

```
dive
 |-- dive_app
 |-- dive_core
 |-- dive_ui
 |-- LICENSE
 |-- README.md
 |-- TODO.md
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
