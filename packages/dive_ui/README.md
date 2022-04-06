# dive_ui

A Flutter package (part of the [Dive](https://pub.dev/packages/dive) toolkit) containing Widgets for building Flutter apps for
video recording and streaming.

[![pub package](https://img.shields.io/pub/v/dive_ui.svg)](https://pub.dev/packages/dive_ui)
<a href="https://www.buymeacoffee.com/larryaasen">
  <img alt="Gift me a coffee" src="https://img.shields.io/badge/Donate-Gift%20Me%20A%20Coffee-yellow.svg">
</a>

## Introduction

Dive is a Flutter toolkit for video recording and streaming. The dive_ui
package is part of the Dive toolkit and is a complete set of widgets to build
the next generation of Flutter media apps. This package relies heavily on the
[dive](https://pub.dev/packages/dive) package but remains platform indepenent. There are many widgets in this package
and plenty of examples.

# Video Widgets
* DiveSourceCard - stack, gear menu, child
* DiveMediaPreview - stack, text, buttons
* DiveMeterPreview - A [DivePreview] with a [DiveAudioMeter] overlay using a [DiveAudioMeterSource].
* DivePreview - A widget showing a preview of a video/image frame using a [Texture] widget.
* DiveGrid - GridView

# Audio Widgets
* DiveAudioMeter: A widget to display a multi-channel audio meter.
* DiveAudioMeterSource: A class for the volume meter data and processing.

# Other Widgets
* DivePositionDialog - A dialog to update the position of a scene item.
* DivePositionEdit - Update the position of a scene item.
* DiveMoveItemEdit - Update the z-priority of a scene item.
* DiveSideSheet - Show a Material side sheet.
* DiveStreamSettingsButton - An icon button that presents the stream settings dialog.
* DiveStreamSettingsDialog - A dialog to update the video output settings.
* DiveTopicCard - A material design widget that creates a [Card] widget that contains content and actions about a single subject.
* DiveIconSet - The default icons for dive_ui widgets. Override these methods to provide custom icons.
* DiveUIApp - Setup DiveUI before the first [build] is called.
* DiveUI - Contains the key setup method.
* DiveMediaPlayButton - Play media button.
* DiveMediaStopButton - Stop media button.
* DiveMediaDuration - Media duration text.
* DiveMediaButtonBar - A button bar containing DiveMediaDuration, DiveMediaPlayButton,
and DiveMediaStopButton.
* DiveOutputButton - Streaming output button.
* DiveStreamPlayButton - Streaming play button.
* DiveAspectRatio - A widget that will size the child to a specific aspect ratio.
* DiveGrid - A grid of widgets that maaintains the aspect ratio.
* DiveSourceMenu - 
* DiveSubMenu - A popup menu.
* DiveImagePickerButton - An icon button that presents the image file picker dialog.
* DiveVideoPickerButton - An icon button that presents the video file picker dialog.
* DiveCameraList - A widget that displays a vertical list of the video cameras.
* DiveAudioList - A widget that displays a vertical list of the audio sources.
* DiveSettingsButton - An icon button that presents the settings dialog.
* DiveVideoSettingsDialog - A dialog to update the video output settings.
