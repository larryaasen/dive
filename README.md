# Dive

Dive is a video platform built on top of Dart and Flutter with native
extensions on multiple platforms.

## Introduction

DiveCore - a Flutter plugin package that provides video capabilities.

DiveUI - a Flutter plugin package that provides Widgets for Flutter apps using DiveCore.

DiveApp - a Flutter app for video recording and streaming.

## DiveCore

The DiveCore package is a Flutter plugin that provides low level services for
video playback, camera devices, live streaming, all with audio. This package
contains platform-specific implementations with native extensions for Android,
iOS, and macOS.

## DiveUI

The DiveUI package is a Flutter package containing Widgets to build video based
Flutter apps. This package relies heavily on the DiveCore package but remains
platform indepenent.

## DiveApp

The DiveApp app is a Flutter app for video live streaming that uses Wigets from
the DiveUI package. This app has code that is platform independent, but will
only run on the platforms supported by DiveCore, which for now is
Android, iOS, and macOS.

## Folder Structure

```
dive
 |-- dive_app
 |-- dive_core
 |-- dive_ui
```


## Misc

Build a modern live streaming app to replace OBS.
Create a Flutter app in Dart that runs on Mac, Windows and iPad.
This could be an ad supported app, or free and open-source software.
Stream to: Twitch, YouTube, Vimeo
Available in many languages.

***Do I need to use libobs?

Main Use Case:
- open app
- default video camera is displayed
- click stream button
- stream config dialog is displayed
- enter Twitch stream credentials
- click Stream button
- video camera starts streaming to Twitch

Architecture
- logging
- configuration
- layout of screen
- titles and graphics
- plugins
- analytics
- macros
- About


Logging
- log all events to a user accessible file

Configuration
- app default configuration
- user configuration
- project level configuration
- template configuration

Layout Organizer
- program in upper right corner
- list of desired panels
- optional template name
- default template
- layout configuration: combination of template and overrides
- each panel has an aspect ratio
- panels: program, preview, source 1, source 2, source 3, audio mixer, buttons, clock
- panel types: base panel, video panel, program panel, preview panel

Output
- 

Titles and Graphics
- overlay

Analytics
- provide in app analytics screens
- support remote analytics for Google Analytics, Firebase Analytics, etc.

Plugins
- create a flexible plugin architecture to support many different features including graphics, logging, layout, streaming providers, analytics

Macros
-event macros
-macros can be connected to buttons on the screen


About
- copyright
- version

## Concepts

### devices

The device is a camera, microphone, virtual camera, or NDI source.

### video


### sources

### channel

### output

A source is an instance of content type.

### content types

- audio
- video
- image
- camera
- screen capture
