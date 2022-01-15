import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The state of a [TextureController].
class DivePreviewValue {
  /// Creates a new controller state.
  const DivePreviewValue({
    this.isInitialized,
    this.errorDescription,
  });

  /// Creates a new controller state for an uninitialzed controller.
  const DivePreviewValue.uninitialized()
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
  DivePreviewValue copyWith({
    bool isInitialized,
    String errorDescription,
  }) {
    return DivePreviewValue(
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
class DivePreviewException implements Exception {
  /// Creates a new exception with the given error code and description.
  DivePreviewException(this.code, this.description);

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
/// TODO: rename TextureController with a Dive prefix.
class TextureController extends ValueNotifier<DivePreviewValue> {
  final String trackingUUID;

  /// Creates a new controller in an uninitialized state.
  TextureController({this.trackingUUID})
      : super(const DivePreviewValue.uninitialized());

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
  /// Throws a [DivePreviewException] if the initialization fails.
  Future<void> initialize() async {
    ArgumentError.checkNotNull(trackingUUID, 'trackingUUID');
    if (_isDisposed || value.isInitialized) {
      return Future<void>.value();
    }
    try {
      _creatingCompleter = Completer<void>();

      final int textureId = null;
      _textureId = textureId;
      value = value.copyWith(
        isInitialized: true,
      );
    } on PlatformException catch (e) {
      throw DivePreviewException(e.code, e.message);
    }
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
      await _eventSubscription?.cancel();
    }
  }
}
