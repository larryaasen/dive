import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dive_av_input_type.dart';
import 'dive_av_platform_interface.dart';

/// An implementation of [DiveAvPlatform] that uses method channels.
class MethodChannelDiveAv extends DiveAvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dive_av.io/plugin');

  @override
  Future<String?> createVideoSource(
      String deviceUniqueID, int? textureId) async {
    final rv = await methodChannel.invokeMethod<String?>('createVideoSource', {
      'device_uique_id': deviceUniqueID,
      'texture_id': textureId,
    });
    return rv;
  }

  @override
  Future<bool> removeSource({required String sourceId}) async {
    final rv = await methodChannel
            .invokeMethod<bool>('removeSource', {'source_id': sourceId}) ??
        false;
    return rv;
  }

  @override
  Future<int> initializeTexture() async {
    final rv = await methodChannel.invokeMethod<int>('initializeTexture') ?? 0;
    return rv;
  }

  @override
  Future<bool> disposeTexture(int textureId) async {
    final rv = await methodChannel
            .invokeMethod<bool>('disposeTexture', {'textureId': textureId}) ??
        false;
    return rv;
  }

  @override
  Future<List<DiveAVInputType>> inputsFromType(String typeId) async {
    final rv = await methodChannel.invokeMethod<dynamic>('inputsFromType');
    final inputs = <DiveAVInputType>[];
    if (rv is List) {
      for (final input in rv) {
        if (input is Map) {
          final uniqueID = input['uniqueID'] as String?;
          final localizedName = input['localizedName'] as String?;
          final typeId = input['typeId'] as String?;
          if (uniqueID != null && localizedName != null && typeId != null) {
            final inputType = DiveAVInputType(
                uniqueID: uniqueID,
                typeId: typeId,
                localizedName: localizedName);
            inputs.add(inputType);
          }
        }
      }
    }

    return inputs;
  }
}
