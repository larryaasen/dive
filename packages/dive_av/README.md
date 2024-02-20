# dive_av

Dive AV

## macOS Setup

The minimum macOS version supported is 13.0 and above.

In macOS, you also need to enable the following entitlements in Signing & Capabilities for your app targets:

- If your app uses device cameras, enable the Camera Entitlement.
- If your app uses device microphones, enable the Audio Input Entitlement.

You also need to include the NSCameraUsageDescription key in your app’s Info.plist file.

