import 'package:dive_core/dive_sources.dart';
import 'package:dive_core/dive_input.dart';
import 'package:dive_core/dive_input_type.dart';
import 'package:dive_obslib/dive_plugin.dart';

extension DivePluginExt on DivePlugin {
  static Future<DiveTransformInfo> getSceneItemInfo(
      String sceneUUID, int itemId) async {
    final Map info = await DivePlugin.getSceneItemInfoMap(sceneUUID, itemId);
    return DiveTransformInfo.fromMap(info);
  }

  static Future<bool> setSceneItemInfo(
      String sceneUUID, int itemId, DiveTransformInfo info) {
    return DivePlugin.setSceneItemInfo(sceneUUID, itemId, info.toMap());
  }

  static Future<List<DiveInputType>> inputTypes() async {
    final devices = await DivePlugin.inputTypesList();
    return devices.map(DiveInputType.fromJson).toList();
  }

  static Future<List<DiveInput>> inputsFromType(String typeId) async {
    final devices = await DivePlugin.inputsListFromType(typeId);
    return devices.map(DiveInput.fromMap).toList();
  }

  static Future<List<DiveInput>> audioInputs() async {
    final devices = await DivePlugin.audioInputsList();
    return devices.map(DiveInput.fromMap).toList();
  }

  static Future<List<DiveInput>> videoInputs() async {
    final devices = await DivePlugin.videoInputsList();
    return devices.map(DiveInput.fromMap).toList();
  }
}
