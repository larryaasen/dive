import 'dart:async';

import 'package:dive_obslib/dive_obslib.dart';
import 'package:flutter/services.dart';

/// This is thrown by [DiveTextureController] when the plugin reports an error.
class DiveTextureException implements Exception {
  /// Creates a new exception with the given error code and description.
  DiveTextureException(this.code, this.description);

  /// Error code.
  String code;

  /// Textual description of the error.
  String? description;

  @override
  String toString() => '$runtimeType($code, $description)';
}

/// Creates and owns a native texture.
///
/// Before using a [DiveTextureController] a call to [initialize] must complete.
class DiveTextureController {
  final String? trackingUUID;

  /// Creates a new controller in an uninitialized state.
  DiveTextureController({this.trackingUUID});

  /// Checks whether [DiveTextureController.dispose] has completed successfully.
  bool get isDisposed => _isDisposed;

  /// Has the texture been initialized.
  bool get isInitialized => _isInitialized;

  /// The texture ID provided after initialization.
  int? get textureId => _textureId;

  int? _textureId;
  bool _isInitialized = false;
  bool _isDisposed = false;
  Completer<void>? _creatingCompleter;

  /// Initializes the texture.
  ///
  /// Throws a [DiveTextureException] if the initialization fails.
  Future<void> initialize() async {
    ArgumentError.checkNotNull(trackingUUID, 'trackingUUID');
    if (_isDisposed || _isInitialized) {
      return Future<void>.value();
    }
    try {
      _creatingCompleter = Completer<void>();

      final int textureId = await obslib.initializeTexture(trackingUUID: trackingUUID!);
      _textureId = textureId;
      _isInitialized = true;
    } on PlatformException catch (e) {
      throw DiveTextureException(e.code, e.message);
    }
    _creatingCompleter!.complete();
    return _creatingCompleter!.future;
  }

  /// Releases the resources held by this controller.
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      await obslib.disposeTexture(_textureId!);
    }
  }
}
