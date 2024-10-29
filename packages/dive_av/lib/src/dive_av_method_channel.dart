// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dive_av_input.dart';
import 'dive_av_platform_interface.dart';

/// An implementation of [DiveAvPlatform] that uses method channels.
class MethodChannelDiveAv extends DiveAvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final channel = const MethodChannel('dive_av.io/plugin');

  @visibleForTesting
  final channelCallback = const MethodChannel('dive_av.io/plugin/callback');

  MethodChannelDiveAv() {
    channelCallback.setMethodCallHandler(callbacksHandler);
  }

  static final _volumeMeterCallbacks = <String, DiveAvVolumeMeterCallback>{};

  Future<dynamic> callbacksHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'volmeter':
        final sourceId = methodCall.arguments['source_id'] as String;

        List<double>? magnitude, peak, inputPeak;
        try {
          magnitude = methodCall.arguments['magnitude'].cast<double>().toList();
          peak = methodCall.arguments['peak'].cast<double>().toList();
          inputPeak = methodCall.arguments['inputPeak'].cast<double>().toList();
        } catch (e, s) {
          print("exception: $e\n$s");
        }

        final callback = _volumeMeterCallbacks[sourceId];
        if (callback != null) {
          try {
            callback(sourceId, magnitude ?? [], peak ?? [], inputPeak ?? []);
          } catch (e, s) {
            print(
                "DivePluginObslib.callbacksHandler: exception calling callback: $e\n$s");
          }
        }
        return true;
      default:
        throw MissingPluginException(
            'method name `${methodCall.method}` not implemented');
    }
  }

  /// Creates an audio source and returns the source id.
  @override
  Future<String?> createAudioSource(String deviceUniqueID,
      DiveAvVolumeMeterCallback? volumeMeterCallback) async {
    final sourceId = await channel.invokeMethod<String?>('createAudioSource', {
      'device_uique_id': deviceUniqueID,
    });
    if (sourceId != null && volumeMeterCallback != null) {
      _volumeMeterCallbacks[sourceId] = volumeMeterCallback;
    }
    return sourceId;
  }

  @override
  Future<String?> createVideoSource(
      String deviceUniqueID, int? textureId) async {
    final rv = await channel.invokeMethod<String?>('createVideoSource', {
      'device_uique_id': deviceUniqueID,
      'texture_id': textureId,
    });
    return rv;
  }

  @override
  Future<bool> removeSource({required String sourceId}) async {
    _volumeMeterCallbacks.remove(sourceId);
    final rv = await channel
            .invokeMethod<bool>('removeSource', {'source_id': sourceId}) ??
        false;

    return rv;
  }

  @override
  Future<int> initializeTexture() async {
    final rv = await channel.invokeMethod<int>('initializeTexture') ?? 0;
    return rv;
  }

  @override
  Future<bool> disposeTexture(int textureId) async {
    final rv = await channel
            .invokeMethod<bool>('disposeTexture', {'textureId': textureId}) ??
        false;
    return rv;
  }

  @override
  Future<List<DiveAVInput>> inputsFromType(String typeId) async {
    final rv = await channel
        .invokeMethod<dynamic>('inputsFromType', {'typeId': typeId});
    final inputs = <DiveAVInput>[];
    if (rv is List) {
      for (final input in rv) {
        if (input is Map) {
          final inputType = DiveAVInput.fromMap(input);
          if (inputType != null) {
            inputs.add(inputType);
          }
        }
      }
    }

    return inputs;
  }
}
