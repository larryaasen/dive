import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dive_av_input.dart';
import 'dive_av_method_channel.dart';

/// Signature of VolumeMeter callback.
typedef DiveAvVolumeMeterCallback = void Function(String deviceUniqueID,
    List<double> magnitude, List<double> peak, List<double> inputPeak);

abstract class DiveAvPlatform extends PlatformInterface {
  /// Constructs a DiveAvPlatform.
  DiveAvPlatform() : super(token: _token);

  static final Object _token = Object();

  static DiveAvPlatform _instance = MethodChannelDiveAv();

  /// The default instance of [DiveAvPlatform] to use.
  ///
  /// Defaults to [MethodChannelDiveAv].
  static DiveAvPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DiveAvPlatform] when
  /// they register themselves.
  static set instance(DiveAvPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> createAudioSource(
      String deviceUniqueID, DiveAvVolumeMeterCallback? volumeMeterCallback) {
    throw UnimplementedError('createAudioSource has not been implemented.');
  }

  Future<String?> createVideoSource(String deviceUniqueID, int? textureId) {
    throw UnimplementedError('createVideoSource has not been implemented.');
  }

  Future<bool> removeSource({required String sourceId}) {
    throw UnimplementedError('removeSource has not been implemented.');
  }

  Future<int> initializeTexture() {
    throw UnimplementedError('initializeTexture has not been implemented.');
  }

  Future<bool> disposeTexture(int textureId) {
    throw UnimplementedError('disposeTexture has not been implemented.');
  }

  Future<List<DiveAVInput>> inputsFromType(String typeId) {
    throw UnimplementedError('inputsFromType has not been implemented.');
  }
}
