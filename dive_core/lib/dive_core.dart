library dive_core;

import 'package:riverpod/riverpod.dart';

export 'dive_input_type.dart';
export 'dive_input.dart';
export 'dive_media_source.dart';
export 'dive_sources.dart';
export 'texture_controller.dart';

/// A callback used by providers to create the value exposed.
///
/// If an exception is thrown within that callback, all attempts at reading
/// the provider associated with the given callback will throw.
///
/// The parameter [ref] can be used to interact with other providers
/// and the life-cycles of this provider.
///
/// See also:
///
/// - [ProviderReference], which exposes the methods to read other providers.
/// - [Provider], a provider that uses [Create] to expose an immutable value.

class DiveCore {
  /// For use with Riverpod
  static ProviderContainer providerContainer;

  static Result notifierFor<Result>(ProviderBase<Object, Result> provider) {
    if (DiveCore.providerContainer == null) {
      throw ProviderContainerException();
    }
    return DiveCore.providerContainer != null
        ? DiveCore.providerContainer.read(provider)
        : null;
  }
}

class ProviderContainerException implements Exception {
  String errMsg() => 'DiveCore.providerContainer should not be null.';
}
