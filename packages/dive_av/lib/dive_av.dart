import 'src/dive_av_input.dart';
import 'src/dive_av_platform_interface.dart';

export 'src/dive_av_input.dart';

class DiveAv {
  Future<String?> createAudioSource(String deviceUniqueID,
      DiveAvVolumeMeterCallback? volumeMeterCallback) async {
    return DiveAvPlatform.instance
        .createAudioSource(deviceUniqueID, volumeMeterCallback);
  }

  Future<String?> createVideoSource(String deviceUniqueID,
      {int? textureId}) async {
    return DiveAvPlatform.instance.createVideoSource(deviceUniqueID, textureId);
  }

  Future<bool> removeSource({required String sourceId}) async {
    return DiveAvPlatform.instance.removeSource(sourceId: sourceId);
  }

  Future<int> initializeTexture() async {
    return DiveAvPlatform.instance.initializeTexture();
  }

  Future<bool> disposeTexture(int textureId) async {
    return DiveAvPlatform.instance.disposeTexture(textureId);
  }

  Future<List<DiveAVInput>> inputsFromType(String typeId) {
    return DiveAvPlatform.instance.inputsFromType(typeId);
  }
}
