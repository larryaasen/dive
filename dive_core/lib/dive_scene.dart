import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';

/// Count of scenes created
int _sceneCount = 0;

class DiveScene extends DiveTracking {
  static const MAX_CHANNELS = 64;

  // TODO: needs to be immutable state
  final List<DiveSceneItem> _sceneItems = [];
  List<DiveSceneItem> get sceneItems => _sceneItems;

  DivePointer pointer;

  static Future<DiveScene> create(String name) async {
    if (_sceneCount > 0) {
      throw UnsupportedError('multiple scenes are not supported.');
    }
    _sceneCount++;

    final scene = DiveScene();
    scene.pointer = obslib.createScene(scene.trackingUUID, name);

    return scene;
  }

  /// Add a source to a scene.
  /// Returns a new scene item.
  Future<DiveSceneItem> addSource(DiveSource source) async {
    final item = obslib.sceneAddSource(pointer, source.pointer);
    final sceneItem = DiveSceneItem(item: item, source: source, scene: this);
    _sceneItems.add(sceneItem);
    return sceneItem;
  }

  /// Finds the scene item for source in this scene.
  DiveSceneItem findSceneItem(DiveSource source) {
    return _sceneItems.firstWhere((sceneItem) => sceneItem.source == source,
        orElse: () => null);
  }

  /// Remove the item from the scene.
  void removeSceneItem(DiveSceneItem sceneItem) {
    if (_sceneItems.remove(sceneItem)) {
      sceneItem.remove();
    }
  }

  /// Remove all items from the scene.
  void removeAllSceneItems() {
    _sceneItems.forEach((sceneItem) {
      sceneItem.remove();
    });
    _sceneItems.clear();
  }

  /// Release the resources associated with this source.
  bool dispose() {
    obslib.deleteScene(pointer);
    removeAllSceneItems();
    pointer = null;
    return true;
  }
}
