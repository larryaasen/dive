import 'package:dive/dive.dart';
import 'package:flutter/material.dart';
import 'dive_position_edit.dart';

/// Update the position of a scene item.
class DivePositionDialog extends StatefulWidget {
  DivePositionDialog({Key? key, this.item}) : super(key: key);

  final DiveSceneItem? item;

  @override
  _DivePositionDialogState createState() => _DivePositionDialogState();
}

class _DivePositionDialogState extends State<DivePositionDialog> {
  DiveTransformInfo? _transformInfo;

  @override
  void initState() {
    widget.item!.getTransformInfo().then((info) {
      setState(() {
        _transformInfo = info;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6200EE),
        title: Text('Position Properties'),
      ),
      body: Center(
        child: Column(children: [
          DivePositionEdit(transformInfo: _transformInfo, onApplyCallback: onApply),
          DiveMoveItemEdit(onSetOrderCallback: onSetOrder),
        ]),
      ),
    );
  }

  void onApply(DiveTransformInfo info) {
    if (widget.item != null) {
      widget.item!.updateTransformInfo(info);
    }
  }

  void onSetOrder(DiveSceneItemMovement move) {
    if (widget.item != null) {
      widget.item!.setOrder(move);
    }
  }
}
