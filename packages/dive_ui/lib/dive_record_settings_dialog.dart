// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:dive/dive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'dive_ui.dart';

/// An icon button that presents the record settings dialog.
class DiveRecordSettingsButton extends StatelessWidget {
  const DiveRecordSettingsButton({Key? key, this.elements}) : super(key: key);

  final DiveCoreElements? elements;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: icon(), onPressed: () => buttonPressed(context));
  }

  /// Override this method to provide a custom icon.
  Icon icon() => Icon(DiveUI.iconSet.recordSettingsButton);

  /// Override this method to provide custom button pressed behavior.
  void buttonPressed(BuildContext context) => presentDialog(context);

  /// Override this method to provide a custom record settings dialog.
  /// Returns [DiveRecordSettingsScreen].
  Widget dialog(BuildContext context) {
    return DiveRecordSettingsScreen(saveFolder: '', onApplyCallback: onApply);
  }

  /// Override this method to provide a custom presenter.
  void presentDialog(BuildContext context) {
    DiveSideSheet.showSideSheet(
        context: context, rightSide: false, width: 500, builder: (BuildContext context) => dialog(context));
  }

  /// Override this method to setup custom recording output.
  void onApply(String saveFolder) {
    if (elements == null) return;

    final state = elements!.state;
    if (state.recordingOutput != null) {
      state.recordingOutput!.stop();
    }
  }
}

/// Signature for when settings need to be applied.
typedef DiveRecordSettingsApplyCallback = void Function(String saveFolder);

/// Update the video output settings.
/// record service URL:
/// record service key:
class DiveRecordSettingsScreen extends StatefulWidget {
  DiveRecordSettingsScreen({
    Key? key,
    this.saveFolder,
    this.useDialog = false,
    this.onApplyCallback,
  }) : super(key: key);

  final String? saveFolder;
  final bool useDialog;
  final DiveRecordSettingsApplyCallback? onApplyCallback;

  @override
  _DiveRecordSettingsScreenState createState() => _DiveRecordSettingsScreenState();
}

class _DiveRecordSettingsScreenState extends State<DiveRecordSettingsScreen> {
  String _saveFolder = '';

  @override
  void initState() {
    super.initState();
    _useInitialState();
  }

  @override
  Widget build(BuildContext context) {
    final title = const Text('Record Settings');
    final content = Center(
      child: Column(children: [
        _buildConfig(context),
      ]),
    );

    if (widget.useDialog) {
      return AlertDialog(title: title, content: content);
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF6200EE), title: title),
      body: content,
    );
  }

  Widget _buildConfig(BuildContext context) {
    final position = Padding(
        padding: EdgeInsets.only(top: 0.0, left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(child: Text('Change Folder'), onPressed: () => _onChangeFolder()),
            Padding(padding: EdgeInsets.only(top: 20), child: Text('Save recordings to this folder:')),
            Container(constraints: BoxConstraints(maxWidth: 400.0), child: Text(_saveFolder)),
          ],
        ));

    final buttons = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(child: Text('Reset'), onPressed: () => _onReset()),
          Container(width: 15),
          ElevatedButton(
            child: Text(widget.useDialog ? 'OK' : 'Apply'),
            onPressed: widget.onApplyCallback == null ? null : _onApply,
          ),
        ]));
    final col = Column(children: [
      position,
      buttons,
    ]);
    return col;
  }

  void _useInitialState() {
    _saveFolder = widget.saveFolder ?? '';
  }

  void _onChangeFolder() async {
    getDirectoryPath(confirmButtonText: 'OK', initialDirectory: '').then((String? path) {
      if (path == null) return;
      DiveSystemLog.message('DiveRecordSettingsScreen: patj=$path', group: 'dive_ui');
      setState(() => _saveFolder = path);
    });
  }

  void _onReset() {
    setState(() {
      _useInitialState();
    });

    ScaffoldMessenger.maybeOf(context)!.showSnackBar(SnackBar(
      content: Text("Properties set back to their original values."),
    ));
  }

  void _onApply() {
    if (widget.onApplyCallback == null) return;
    widget.onApplyCallback?.call(_saveFolder);

    if (!widget.useDialog) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Properties have been applied.")));
    }
  }
}
