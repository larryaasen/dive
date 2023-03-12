// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:riverpod/riverpod.dart';

import 'dive_core.dart';

/// The state for a service.
class TemplateState {
  const TemplateState({this.enabled = false});
  final bool enabled;
}

/// A service.
class TemplateService {
  /// Create a Riverpod provider to maintain the state.
  final provider = StateProvider<TemplateState>((ref) => const TemplateState());

  /// The state.
  TemplateState get state => DiveCore.providerContainer.read(provider.notifier).state;

  /// Update the state.
  void updateState(TemplateState newState) {
    final notifier = DiveCore.providerContainer.read(provider.notifier);
    if (notifier.state != newState) {
      notifier.state = newState;
    }
  }

  /// Initialize this service.
  void initialize() async {}
}
