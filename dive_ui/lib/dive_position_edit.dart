import 'package:dive_core/dive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Signature for move edit actoin was pressed.
typedef DiveMoveEditItemCallback = void Function(DiveSceneItemMovement move);

/// Signature for when transform info needs to be applied.
typedef DiveTransformApplyCallback = void Function(DiveTransformInfo info);

class DivePositionEdit extends StatefulWidget {
  DivePositionEdit({Key key, this.transformInfo, this.onApplyCallback})
      : super(key: key);

  final DiveTransformInfo transformInfo;
  final DiveTransformApplyCallback onApplyCallback;

  @override
  _DivePositionEditState createState() => _DivePositionEditState();
}

class _DivePositionEditState extends State<DivePositionEdit> {
  TextEditingController _posXCont = TextEditingController();
  TextEditingController _posYCont = TextEditingController();
  TextEditingController _scaleXCont = TextEditingController();
  TextEditingController _scaleYCont = TextEditingController();
  bool _initialState = true;

  @override
  Widget build(BuildContext context) {
    if (_initialState && widget.transformInfo != null) {
      _useInitialState();
      _initialState = false;
    }
    final decoration = InputDecoration(isDense: true, counterText: "");

    final position = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 60, child: Text('Position', textAlign: TextAlign.end)),
            Container(width: 8),
            Text('X:'),
            Container(width: 5),
            SizedBox(
                width: 50,
                child: TextField(
                  controller: _posXCont,
                  maxLength: 4,
                  decoration: decoration,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                )),
            SizedBox(width: 10),
            Container(width: 5),
            Text('Y:'),
            Container(width: 5),
            SizedBox(
                width: 50,
                child: TextField(
                  controller: _posYCont,
                  maxLength: 4,
                  decoration: decoration,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                )),
            SizedBox(width: 10),
          ],
        ));
    final scale = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 60, child: Text('Scale', textAlign: TextAlign.end)),
            Container(width: 8),
            Text('X:'),
            Container(width: 5),
            SizedBox(
                width: 50,
                child: TextField(
                  controller: _scaleXCont,
                  decoration: decoration,
                )),
            SizedBox(width: 10, child: Text('%')),
            Container(width: 5),
            Text('Y:'),
            Container(width: 5),
            SizedBox(
                width: 50,
                child: TextField(
                  controller: _scaleYCont,
                  decoration: decoration,
                )),
            SizedBox(width: 10, child: Text('%')),
          ],
        ));
    final buttons = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(child: Text('Reset'), onPressed: () => _onReset()),
          Container(width: 15),
          ElevatedButton(
              child: Text('Apply'),
              onPressed: widget.onApplyCallback == null ? null : _onApply),
        ]));
    final col = Column(children: [
      position,
      scale,
      buttons,
    ]);
    return col;
  }

  void _useInitialState() {
    final pos = widget.transformInfo != null ? widget.transformInfo.pos : null;
    final scale =
        widget.transformInfo != null ? widget.transformInfo.scale : null;

    _posXCont.text = pos == null ? '' : pos.x.toInt().toString();
    _posYCont.text = pos == null ? '' : pos.y.toInt().toString();

    _scaleXCont.text =
        scale == null ? '' : (scale.x * 100.0).toStringAsFixed(1);
    _scaleYCont.text =
        scale == null ? '' : (scale.y * 100.0).toStringAsFixed(1);
  }

  void _onReset() {
    setState(() {
      _useInitialState();
    });

    ScaffoldMessenger.maybeOf(context).showSnackBar(SnackBar(
      content: Text("Properties set back to their original values."),
    ));
  }

  void _onApply() {
    if (widget.onApplyCallback == null) return;
    // TODO: improve error handling with text
    final pos =
        DiveVec2(double.parse(_posXCont.text), double.parse(_posYCont.text));
    final scale = DiveVec2(double.parse(_scaleXCont.text) / 100.0,
        double.parse(_scaleYCont.text) / 100.0);
    final info = DiveTransformInfo(pos: pos, scale: scale);

    widget.onApplyCallback(info);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Properties have been applied."),
    ));
  }
}

class DiveMoveItemEdit extends StatefulWidget {
  const DiveMoveItemEdit({Key key, this.onSetOrderCallback}) : super(key: key);

  final DiveMoveEditItemCallback onSetOrderCallback;

  @override
  _DiveMoveItemEditState createState() => _DiveMoveItemEditState();
}

class _DiveMoveItemEditState extends State<DiveMoveItemEdit> {
  @override
  Widget build(BuildContext context) {
    final header =
        Padding(padding: EdgeInsets.only(top: 20), child: Text('Z-Priority'));
    final buttons1 = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
              child: Text('Move Up'),
              onPressed: () => _onMovePressed(DiveSceneItemMovement.MOVE_UP)),
          Container(width: 15),
          ElevatedButton(
              child: Text('Move Top'),
              onPressed: () => _onMovePressed(DiveSceneItemMovement.MOVE_TOP)),
        ]));
    final buttons2 = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
              child: Text('Move Down'),
              onPressed: () => _onMovePressed(DiveSceneItemMovement.MOVE_DOWN)),
          Container(width: 15),
          ElevatedButton(
              child: Text('Move Bottom'),
              onPressed: () =>
                  _onMovePressed(DiveSceneItemMovement.MOVE_BOTTOM)),
        ]));
    final col = Column(children: [
      header,
      buttons1,
      buttons2,
    ]);
    return col;
  }

  void _onMovePressed(DiveSceneItemMovement move) {
    if (widget.onSetOrderCallback != null) {
      widget.onSetOrderCallback(move);
    }
  }
}
