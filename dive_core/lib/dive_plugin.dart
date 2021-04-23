import 'package:dive_core/dive_sources.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_obslib/dive_obslib.dart';

class DivePluginExt {
  static Future<DiveTransformInfo> getSceneItemInfo(
      DivePointer scenePointer, int itemId) async {
    final Map info =
        await obslib.getSceneItemInfoMap(scenePointer.toInt(), itemId);
    return DiveTransformInfo.fromMap(info);
  }

  static Future<bool> setSceneItemInfo(
      DivePointer scenePointer, int itemId, DiveTransformInfo info) {
    return obslib.setSceneItemInfo(scenePointer.toInt(), itemId, info.toMap());
  }

  static List<DiveInputType> inputTypes() {
    final devices = obslib.inputTypes();
    return devices.map(DiveInputType.fromJson).toList();
  }

  static List<DiveInput> inputsFromType(String typeId) {
    final devices = obslib.inputsFromType(typeId);
    return devices.map(DiveInput.fromMap).toList();
  }

  static List<DiveInput> audioInputs() {
    final devices = obslib.audioInputs();
    return devices.map(DiveInput.fromMap).toList();
  }

  static List<DiveInput> videoInputs() {
    final devices = obslib.videoInputs();
    return devices.map(DiveInput.fromMap).toList();
  }
}
