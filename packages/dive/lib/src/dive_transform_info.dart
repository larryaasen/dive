class DiveAlign {
  static const center = 0;
  static const left = (1 << 0);
  static const right = (1 << 1);
  static const top = (1 << 2);
  static const bottom = (1 << 3);

  final int alignment;
  DiveAlign({this.alignment = center});
}

class DiveVec2 {
  final double x, y;

  DiveVec2(this.x, this.y);

  static DiveVec2 fromMap(Map map) {
    assert(map != null);
    return DiveVec2(map['x'], map['y']);
  }

  @override
  String toString() {
    return "x=$x, y=$y";
  }
}

enum DiveBoundsType {
  /// no bounds
  none,

  /// stretch (ignores base scale) */
  stretch,

  /// scales to inner rectangle */
  scaleInner,

  /// scales to outer rectangle */
  scaleOuter,

  /// scales to the width  */
  scaleToWidth,

  /// scales to the height */
  scaletoHeight,

  /// no scaling, maximum size only */
  maxOnly,
}

class DiveTransformInfo {
  final DiveVec2 pos;
  final double rot;
  final DiveVec2 scale;
  final DiveAlign alignment;
  final DiveBoundsType boundsType;
  final DiveAlign boundsAlignment;
  final DiveVec2 bounds;

  DiveTransformInfo(
      {this.pos, this.rot, this.scale, this.alignment, this.boundsType, this.boundsAlignment, this.bounds});

  DiveTransformInfo copyWith({
    pos,
    rot,
    scale,
    alignment,
    boundsType,
    boundsAlignment,
    bounds,
  }) {
    return DiveTransformInfo(
      pos: pos ?? this.pos,
      rot: rot ?? this.rot,
      scale: scale ?? this.scale,
      alignment: alignment ?? this.alignment,
      boundsType: boundsType ?? this.boundsType,
      boundsAlignment: boundsAlignment ?? this.boundsAlignment,
      bounds: bounds ?? this.bounds,
    );
  }

  DiveTransformInfo copyFrom(DiveTransformInfo info) {
    return copyWith(
      pos: info.pos,
      rot: info.rot,
      scale: info.scale,
      alignment: info.alignment,
      boundsType: info.boundsType,
      boundsAlignment: info.boundsAlignment,
      bounds: info.bounds,
    );
  }

  static DiveTransformInfo fromMap(Map map) {
    return DiveTransformInfo(
      pos: DiveVec2.fromMap(map['pos']),
      rot: map['rot'],
      scale: DiveVec2.fromMap(map['scale']),
      alignment: DiveAlign(alignment: map['alignment']),
      boundsType: DiveBoundsType.values[map['bounds_type']],
      boundsAlignment: DiveAlign(alignment: map['bounds_alignment']),
      bounds: DiveVec2.fromMap(map['bounds']),
    );
  }

  Map toMap() {
    return {
      'pos': {'x': pos.x, 'y': pos.y},
      'rot': rot,
      'scale': {'x': scale.x, 'y': scale.y},
      'alignment': alignment.alignment,
      'bounds_type': boundsType.index,
      'bounds_alignment': boundsAlignment.alignment,
      'bounds': {'x': bounds.x, 'y': bounds.y},
    };
  }

  @override
  String toString() {
    return "pos=$pos | scale=$scale";
  }
}
