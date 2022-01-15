class DiveAlign {
  static const CENTER = 0;
  static const LEFT = (1 << 0);
  static const RIGHT = (1 << 1);
  static const TOP = (1 << 2);
  static const BOTTOM = (1 << 3);

  final int alignment;
  DiveAlign({this.alignment = CENTER});
}

class DiveVec2 {
  final double x, y;

  DiveVec2(this.x, this.y);

  static DiveVec2 fromMap(Map map) => DiveVec2(map['x'], map['y']);

  @override
  String toString() {
    return "x=$x, y=$y";
  }
}

enum DiveBoundsType {
  /// no bounds
  NONE,

  /// stretch (ignores base scale) */
  STRETCH,

  /// scales to inner rectangle */
  SCALE_INNER,

  /// scales to outer rectangle */
  SCALE_OUTER,

  /// scales to the width  */
  SCALE_TO_WIDTH,

  /// scales to the height */
  SCALE_TO_HEIGHT,

  /// no scaling, maximum size only */
  MAX_ONLY,
}

class DiveTransformInfo {
  final DiveVec2? pos;
  final double? rot;
  final DiveVec2? scale;
  final DiveAlign? alignment;
  final DiveBoundsType? boundsType;
  final DiveAlign? boundsAlignment;
  final DiveVec2? bounds;

  DiveTransformInfo(
      {this.pos,
      this.rot,
      this.scale,
      this.alignment,
      this.boundsType,
      this.boundsAlignment,
      this.bounds});

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
      'pos': {'x': pos?.x ?? 0, 'y': pos?.y ?? 0},
      'rot': rot,
      'scale': {'x': scale?.x ?? 0, 'y': scale?.y ?? 0},
      'alignment': alignment?.alignment,
      'bounds_type': boundsType?.index,
      'bounds_alignment': boundsAlignment?.alignment,
      'bounds': {'x': bounds?.x ?? 0, 'y': bounds?.y ?? 0},
    };
  }

  @override
  String toString() {
    return "pos=$pos | scale=$scale";
  }
}
