# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0]

- Updated dive package to use flutter_lints 1.0.4 and updated code to conform to the lints.

## [0.4.0]

- Updated dependency versions for intl and riverpod, to resolve static analysis warnings.
- Added DiveSettings class.
- Added a list of DiveSources to DiveCoreElementsState.
- Added DiveSource create method for creating any source.
- Added monitoring types and audio level.
- Added DiveMediaSourceSettings.
- Changed name of addMediaSource to addLocalVideoMediaSource and use DiveMediaSourceSettings
when creating the source.
- Fixed issues with DiveOutput and streaming to the auto server of Twitch.

## [0.3.0]

- Added class `DiveRTMPServices` to provide a list of streaming services.
- Added service and server to `DiveOutput`.

## [0.2.0]
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

## [0.1.0]

The first release incorporating the use of dive_obslib.

## [0.1.0-alpha.1]

Initial release of alpha code. Not ready for production use. More features to
be added soon.
