import 'package:flutter/material.dart';

import 'dive_image_source.dart';
import 'dive_input.dart';
import 'dive_input_type.dart';
import 'dive_media_source.dart';
import 'dive_properties.dart';
import 'dive_source.dart';
import 'dive_text_clock_source.dart';

/// Provides a list of sources.
abstract class DiveInputProvider {
  /// Create a [DiveSource] for the [input].
  DiveSource? create(String? name, DiveCoreProperties? properties);

  /// Discovers and provides a list of inputs by this input provider.
  Future<List<DiveInput>?> inputs();

  /// Provides a list of input types supported by this input provider.
  List<DiveInputType> inputTypes();
}

/// The standard image input provider that creates [DiveImageSource].
class DiveTextClockInputProvider extends DiveInputProvider {
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.text];

  @override
  Future<List<DiveInput>> inputs() => Future.value([]);

  /// Create a [DiveSource] for the [input].
  /// TODO: maybe this should be a static method because this class has
  /// no instance variables?
  @override
  DiveSource? create(String? name, DiveCoreProperties? properties) {
    return DiveTextClockSource.create(name: name, properties: properties);
  }
}

/// The standard image input provider that creates [DiveImageSource].
class DiveImageInputProvider extends DiveInputProvider {
  DiveImageInputProvider();

  /// The local filename to be loaded.
  static const String PROPERTY_FILENAME = 'filename';

  /// The resource name to be loaded.
  static const String PROPERTY_RESOURCE_NAME = 'resource_name';

  /// The remote URL to be loaded.
  static const String PROPERTY_URL = 'url';

  /// Discovers and provides a list of inputs.
  @override
  Future<List<DiveInput>> inputs() => Future.value([]);

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.image];

  /// Create a [DiveSource] for the [input].
  /// TODO: maybe this should be a static method because this class has
  /// no instance variables?
  @override
  DiveSource? create(String? name, DiveCoreProperties? properties) {
    return DiveImageSource.create(name: name, properties: properties);
  }
}

/// The standard media input provider that creates [DiveMediaSource].
class DiveMediaInputProvider extends DiveInputProvider {
  DiveMediaInputProvider();

  /// The local filename to be loaded.
  static const String PROPERTY_FILENAME = 'filename';

  /// The remote URL to be loaded.
  static const String PROPERTY_URL = 'url';

  /// Discovers and provides a list of inputs.
  @override
  Future<List<DiveInput>> inputs() => Future.value([]);

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.media];

  /// Create a [DiveSource] for the [input].
  @override
  DiveSource? create(String? name, DiveCoreProperties? properties) {
    return DiveMediaSource.create(name: name, properties: properties);
  }
}

class DiveInputProviders {
  /// These are the standard input providers.
  static final standardInputProviders = [
    DiveImageInputProvider(),
    DiveTextClockInputProvider(),
  ];

  /// The list of providers.
  static List<DiveInputProvider> get all => _all;

  /// The internal list of providers.
  static final List<DiveInputProvider> _all = standardInputProviders;

  /// Registers a new provider to the list of providers.
  static bool registerProvider(DiveInputProvider newProvider) {
    final any = _all.any((provider) => newProvider == provider);
    if (any) {
      return false;
    }
    _all.add(newProvider);
    return true;
  }
}
