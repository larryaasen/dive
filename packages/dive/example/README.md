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
* Start streaming to Twitch.
* Usage: flutter run lib/main_example4.dart -d macos