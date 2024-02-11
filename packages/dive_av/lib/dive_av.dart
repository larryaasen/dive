import 'dive_av_platform_interface.dart';

class DiveAv {
  Future<String?> createVideoSource(String deviceUniqueID) async {
    return DiveAvPlatform.instance.createVideoSource(deviceUniqueID);
  }

  Future<bool> removeSource({required String sourceId}) async {
    return DiveAvPlatform.instance.removeSource(sourceId: sourceId);
  }
}
