# dive_av

Dive AV

## macOS Setup

The minimum macOS version supported is 13.0 and above.

In macOS, you also need to enable the following entitlements in Signing & Capabilities for your app targets:

- If your app uses device cameras, enable the Camera Entitlement.
- If your app uses device microphones, enable the Audio Input Entitlement.

You also need to include the NSCameraUsageDescription key in your app’s Info.plist file.

## Current High Level Features

- Update a Flutter texture with AV video frames.
- Get a list of AV input types.

## Current Low Level Features
- Capture AV video frames.
- Create Flutter textures.
- Copy AV video frames to Flutter textures.

## TODO

- Capture AV audio frames.
- Update the audio system with AV audio frames.
- Record AV video and audio frames into a file.
- Add support for UVC for controlling video cameras.
