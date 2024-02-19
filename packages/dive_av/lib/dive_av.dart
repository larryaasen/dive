import 'dive_av_platform_interface.dart';

class DiveAv {
  Future<String?> createVideoSource(String deviceUniqueID, {int? textureId}) async {
    return DiveAvPlatform.instance.createVideoSource(deviceUniqueID, textureId);
  }

  Future<bool> removeSource({required String sourceId}) async {
    return DiveAvPlatform.instance.removeSource(sourceId: sourceId);
  }

  Future<int> initializeTexture() async {
    return DiveAvPlatform.instance.initializeTexture();
  }
}
