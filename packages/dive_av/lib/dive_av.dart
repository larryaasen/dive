import 'src/dive_av_input_type.dart';
import 'src/dive_av_platform_interface.dart';

export 'src/dive_av_input_type.dart';

class DiveAv {
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

  Future<List<DiveAVInputType>> inputsFromType(String typeId) {
    return DiveAvPlatform.instance.inputsFromType(typeId);
  }
}
