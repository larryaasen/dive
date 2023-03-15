## 0.7.0

- Added path parameter to the start method of the DiveRecordingOutput class.
- Added DiveRecordingOutput to DiveCoreElementsState for recording.
- Fixed the use of obs-ffmpeg-mux for recording so now recording while streaming works.
- Bumped dive_obslib to 0.5.0.

## 0.6.0

- Converted all code to null safety.
- Added support for multiple scenes, and added Example 14 to demonstrate multiple scenes.
- Updated all examples.
- Minimum Dart version required is now 2.19.0 and Flutter is 3.7.0.
- Updated many of the package dependency versions including Riverpod, uuid, ffi, ffigen, and path_provider.
- Updated the use of Riverpod to version 2.3.1, and changed use of StateNotifierProvider to StateProvider.
- Added recording features that are not yet finished.
- Renamed DiveOutput to DiveStreamingOutput.

## 0.5.0

- Updated dive package to use flutter_lints 1.0.4 and updated code to conform to the lints.

## 0.4.0

- Updated dependency versions for intl and riverpod, to resolve static analysis warnings.
- Added DiveSettings class.
- Added a list of DiveSources to DiveCoreElementsState.
- Added DiveSource create method for creating any source.
- Added monitoring types and audio level.
- Added DiveMediaSourceSettings.
- Changed name of addMediaSource to addLocalVideoMediaSource and use DiveMediaSourceSettings
when creating the source.
- Fixed issues with DiveOutput and streaming to the auto server of Twitch.

## 0.3.0

- Added class `DiveRTMPServices` to provide a list of streaming services.
- Added service and server to `DiveOutput`.

## 0.2.0
### Changed

- Updated to dive_obslib 0.1.0.
- Mininum Dart SDK version is now 2.10.0.
- Updated example.
- Renamed TextureController to DiveTextureController.
- Changed DiveCoreElementsState to be immutable.
- Improved DiveCoreElements.
- Fixed issue with formatDuration milliseconds rounding.
- Fixed issues with DiveOutput.
- Small improvements to Dive sources.

### Added

- Added default audio monitoring.

## 0.1.0

The first release incorporating the use of dive_obslib.

## 0.1.0-alpha.1

Initial release of alpha code. Not ready for production use. More features to
be added soon.
