import 'package:dive_obslib/dive_obslib.dart';

import 'dive_transform_info.dart';

class DivePluginExt {
  static Future<DiveTransformInfo> getSceneItemInfo(DivePointerSceneItem item) async {
    final Map info = await obslib.getSceneItemInfoMap(item.toInt());
    return DiveTransformInfo.fromMap(info);
  }

  static Future<bool> setSceneItemInfo(DivePointerSceneItem item, DiveTransformInfo info) {
    return obslib.setSceneItemInfo(item.toInt(), info.toMap());
  }
}
