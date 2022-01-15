import 'package:dive_core/dive_input.dart';

import 'dive_input_type.dart';
import 'dive_media_source.dart';
import 'dive_properties.dart';
import 'dive_sources.dart';

/// Provides a list of sources.
abstract class DiveInputProvider {
  /// Create a [DiveSource] for the [input].
  DiveSource create(String name, DiveCoreProperties properties);

  /// Discovers and provides a list of inputs.
  List<DiveInput> inputs();

  /// Provides a list of input types.
  List<DiveInputType> inputTypes();
}

/// The standard image input provider that creates [DiveImageSource].
class DiveImageInputProvider extends DiveInputProvider {
  DiveImageInputProvider() {}

  /// The local filename to be loaded.
  static const String PROPERTY_FILENAME = 'filename';

  /// The remote URL to be loaded.
  static const String PROPERTY_URL = 'url';

  /// Discovers and provides a list of inputs.
  @override
  List<DiveInput> inputs() => [];

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.image];

  /// Create a [DiveSource] for the [input].
  @override
  DiveSource create(String name, DiveCoreProperties properties) {
    return DiveImageSource.create(name: name, properties: properties);
  }
}

/// The standard media input provider that creates [DiveMediaSource].
class DiveMediaInputProvider extends DiveInputProvider {
  DiveMediaInputProvider() {}

  /// The local filename to be loaded.
  static const String PROPERTY_FILENAME = 'filename';

  /// The remote URL to be loaded.
  static const String PROPERTY_URL = 'url';

  /// Discovers and provides a list of inputs.
  @override
  List<DiveInput> inputs() => [];

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.media];

  /// Create a [DiveSource] for the [input].
  @override
  DiveSource create(String name, DiveCoreProperties properties) {
    return DiveMediaSource.create(name: name, properties: properties);
  }
}

/// The standard video input provider.
/// TODO: this class needs to be moved to a plugin package.
class DiveVideoInputProvider extends DiveInputProvider {
  /// Discovers and provides a list of inputs.
  @override
  List<DiveInput> inputs() =>
      [DiveInput(id: 'camera1', name: 'camera1', type: DiveInputType.video)];

  /// Provides a list of input types.
  @override
  List<DiveInputType> inputTypes() => [DiveInputType.video];

  /// Create a [DiveSource] for the [input].
  @override
  DiveSource create(String name, DiveCoreProperties properties) {
    return null;
  }
}

class DiveInputProviders {
  /// These are the standard input providers.
  static final _standardInputProviders = [
    DiveImageInputProvider(),
    DiveVideoInputProvider()
  ];

  /// The internal list of providers.
  final List<DiveInputProvider> _providers = _standardInputProviders;

  /// Returns the list of providers.
  List<DiveInputProvider> get providers => _providers;

  /// Add a new custom provider to the list of providers.
  void addProvider(DiveInputProvider provider) => _providers.add(provider);
}
