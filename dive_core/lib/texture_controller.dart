import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:dive_obslib/dive_obslib.dart';

/// The state of a [TextureController].
class PreviewValue {
  /// Creates a new controller state.
  const PreviewValue({
    this.isInitialized,
    this.errorDescription,
  });

  /// Creates a new controller state for an uninitialzed controller.
  const PreviewValue.uninitialized()
      : this(
          isInitialized: false,
        );

  /// True after [TextureController.initialize] has completed successfully.
  final bool isInitialized;

  /// Description of an error state.
  ///
  /// This is null while the controller is not in an error state.
  /// When [hasError] is true this contains the error description.
  final String errorDescription;

  /// Whether the controller is in an error state.
  ///
  /// When true [errorDescription] describes the error.
  bool get hasError => errorDescription != null;

  /// Creates a modified copy of the object.
  ///
  /// Explicitly specified fields get the specified value, all other fields get
  /// the same value of the current object.
  PreviewValue copyWith({
    bool isInitialized,
    String errorDescription,
  }) {
    return PreviewValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription'
        ')';
  }
}

/// This is thrown when the plugin reports an error.
class PreviewException implements Exception {
  /// Creates a new exception with the given error code and description.
  PreviewException(this.code, this.description);

  /// Error code.
  String code;

  /// Textual description of the error.
  String description;

  @override
  String toString() => '$runtimeType($code, $description)';
}

/// Controls a texture preview.
///
/// Before using a [TextureController] a call to [initialize] must complete.
///
/// To show the texture preview on the screen use a [TexturePreview] widget.
/// TODO: do we need this ValueNotifier?
class TextureController extends ValueNotifier<PreviewValue> {
  final String trackingUUID;

  /// Creates a new controller in an uninitialized state.
  TextureController({this.trackingUUID})
      : super(const PreviewValue.uninitialized());

  int _textureId;
  int get textureId => _textureId;

  bool _isDisposed = false;
  StreamSubscription<dynamic> _eventSubscription;
  Completer<void> _creatingCompleter;

  /// Checks whether [TextureController.dispose] has completed successfully.
  ///
  /// This is a no-op when asserts are disabled.
  void debugCheckIsDisposed() {
    assert(_isDisposed);
  }

  /// Initializes the texture.
  ///
  /// Throws a [PreviewException] if the initialization fails.
  Future<void> initialize() async {
    ArgumentError.checkNotNull(trackingUUID, 'trackingUUID');
    if (_isDisposed || value.isInitialized) {
      return Future<void>.value();
    }
    try {
      _creatingCompleter = Completer<void>();

      final int textureId =
          await obslib.initializeTexture(trackingUUID: trackingUUID);
      _textureId = textureId;
      value = value.copyWith(
        isInitialized: true,
      );
    } on PlatformException catch (e) {
      throw PreviewException(e.code, e.message);
    }
    // _eventSubscription =
    //     EventChannel('dive.io/texture_preview/previewEvents$_textureId')
    //         .receiveBroadcastStream()
    //         .listen(_listener);
    _creatingCompleter.complete();
    return _creatingCompleter.future;
  }

  /// Releases the resources of this controller.
  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    super.dispose();
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      await obslib.disposeTexture(_textureId);
      await _eventSubscription?.cancel();
    }
  }
}
