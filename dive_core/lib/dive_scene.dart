import 'package:dive_core/dive_core.dart';

/// Count of scenes created
int _sceneCount = 0;

class DiveScene extends DiveTracking {
  static const MAX_CHANNELS = 64;

  // TODO: needs to be immutable state
  final List<DiveSceneItem> _sceneItems = [];
  List<DiveSceneItem> get sceneItems => _sceneItems;

  dynamic pointer;

  static Future<DiveScene> create(String name) async {
    if (_sceneCount > 0) {
      throw UnsupportedError('multiple scenes are not supported.');
    }
    _sceneCount++;

    final scene = DiveScene();

    return scene;
  }

  /// Add a source to a scene.
  /// Returns a new scene item.
  Future<DiveSceneItem> addSource(DiveSource source) async {
    final item = DivePointerSceneItem(null);
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
    removeAllSceneItems();
    pointer = null;
    return true;
  }
}
