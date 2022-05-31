# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Changed method `outputGetState` to `streamOutputGetState`.
- Added methods `streamOutputGetServiceNames` and `streamOutputGetServiceServers` to DiveFFIObslib
to get service properties for streaming services.
- Added `modify` method to DiveObslibData.
- Added Int8Extensions.

## [0.1.0]
### Changed

- Updated the ffi package to 1.1.2 and ffigen package to 4.1.3 for null safety.
- Refactored stream output from being one instance to many.
- Mininum Dart SDK version is now 2.10.0.

### Removed

- Removed the uuid package since it was not being used.
- Removed some unit tests.

### Added

- Added DivePointer unit test.
- Added DivePointerOutput class.
- Added shutdowm method to DiveFFIObslib.
- Added comments to code.
- Added audio monitoring improvements.

## [0.0.1]
### Added

- Initial release. A Flutter plugin package that provides low level access to
obslib using FFI.
