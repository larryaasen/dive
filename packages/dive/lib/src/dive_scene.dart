import 'package:collection/collection.dart' show IterableExtension;
import 'package:dive_obslib/dive_obslib.dart';

import 'dive_sources.dart';

/// Count of scenes in use.
int _sceneCount = 0;

class DiveScene extends DiveTracking {
  // TODO: needs to be immutable state
  final List<DiveSceneItem> _sceneItems = [];
  List<DiveSceneItem> get sceneItems => _sceneItems;

  DivePointer? pointer;

  static DiveScene create([String? name]) {
    _sceneCount++;

    final scene = DiveScene();
    name = name ?? 'Scene $_sceneCount';
    scene.pointer = obslib.createScene(scene.trackingUUID, name);
    assert(scene.pointer != null);

    return scene;
  }

  /// Add a source to a scene.
  /// Returns a new scene item.
  Future<DiveSceneItem> addSource(DiveSource source) async {
    assert(pointer != null);
    final item = obslib.sceneAddSource(pointer!, source.pointer!);
    final sceneItem = DiveSceneItem(item: item, source: source, scene: this);
    _sceneItems.add(sceneItem);
    return sceneItem;
  }

  /// Finds the scene item for source in this scene.
  DiveSceneItem? findSceneItem(DiveSource source) {
    return _sceneItems.firstWhereOrNull((sceneItem) => sceneItem.source == source);
  }

  void makeSourceVisible(DiveSource source, bool visible) {
    // Make the old source not visible
    final sceneItem = findSceneItem(source);
    if (sceneItem != null) sceneItem.visible = visible;
  }

  /// Make this scene the primary scene.
  void makeCurrentScene() {
    obslib.changeScene(pointer!);
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
    obslib.deleteScene(pointer!);
    removeAllSceneItems();
    pointer = null;
    _sceneCount--;
    return true;
  }
}
