import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dive_av_platform_interface.dart';

/// An implementation of [DiveAvPlatform] that uses method channels.
class MethodChannelDiveAv extends DiveAvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dive_av.io/plugin');

  @override
  Future<String?> createVideoSource(String deviceUniqueID, int? textureId) async {
    final rv = await methodChannel.invokeMethod<String?>('createVideoSource', {
      'device_uique_id': deviceUniqueID,
      'texture_id': textureId,
    });
    return rv;
  }

  @override
  Future<bool> removeSource({required String sourceId}) async {
    final rv = await methodChannel.invokeMethod<bool>('removeSource', {'source_id': sourceId}) ?? false;
    return rv;
  }

  @override
  Future<int> initializeTexture() async {
    final rv = await methodChannel.invokeMethod<int>('initializeTexture') ?? 0;
    return rv;
  }
}
