# Dive

# Warning: This is the initial release of alpha code. Not ready for production use. More features to be added soon.

Introducing Dive! A new Flutter toolkit for video recording and streaming.
A complete set of packages to build the next generation of Flutter media apps.

## Introduction

Dive is a video recording and streaming toolkit built on top of Dart and
Flutter with native extensions on macOS. It is a group of Flutter packages for
building media apps. In the future, support for multiple
platforms will be added.

## Concepts

A `DiveSource` produces an output stream of frames from a specific input, such as
a FaceTime camera, the main system microphone, or a screen capture.

A `DiveEngine` produces an output stream of frames from an input
stream of frames. There are various types of engines such as a compositing,
filtering, and audio mixing.

A `DiveOutput` producues an output, such as a recording or livestream,
from an input stream of frames.

### Typical Routing
`DiveSource` -> `DiveEngine` -> `DiveOutput`

### Example Routings
`DiveSource` -> `DiveEngine` -> UI widget

`DiveSource`-1:
`DiveSource`-2:
`DiveSource`-3:
`DiveSource`-4:
 -> `DiveScene` -> `DiveEngine`



## Creation Details

This package was created by Larry Aasen on 1/14/2022 using these commands:
```
$ dart --version
Dart SDK version: 2.16.0-80.1.beta (beta) (Mon Dec 13 11:59:02 2021 +0100) on "macos_x64"
$ dart create --template package-simple dive
```
