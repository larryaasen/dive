## 0.5.0

- Added path parameter to the recordingOutputCreate method.

## 0.4.0

- Converted all code to null safety.
- Minimum Dart version required is now 2.19.0 and Flutter is 3.7.0.

## 0.3.0

- Changed DiveFFIObslib inputTypes() to get inputTypes.
- Added example to dive_obslib.
- Added sourceTypes() and sources() to DiveFFIObslib.
- Added setDouble and setInt to DiveObslibData.
- Method `createMediaSource` now supports settings.
- Added serviceName argument to method `streamOutputCreate`, and fixed the issue
with services that use "auto" server URLs.
- Added source set/get volume and monitoring type.

## 0.2.0

- Changed method `outputGetState` to `streamOutputGetState`.
- Added methods `streamOutputGetServiceNames` and `streamOutputGetServiceServers` to DiveFFIObslib
to get service properties for streaming services.
- Added `modify` method to DiveObslibData.
- Added Int8Extensions.

## 0.1.0
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

## 0.0.1
### Added

- Initial release. A Flutter plugin package that provides low level access to
obslib using FFI.
