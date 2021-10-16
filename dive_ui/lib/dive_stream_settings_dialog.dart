import 'package:dive_core/dive_core.dart';
import 'package:flutter/material.dart';
import 'dive_side_sheet.dart';
import 'dive_ui.dart';

/// An icon button that presents the stream settings dialog.
class DiveStreamSettingsButton extends StatelessWidget {
  const DiveStreamSettingsButton({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: icon(), onPressed: () => buttonPressed(context));
  }

  /// Override this method to provide a custom icon.
  Icon icon() => Icon(DiveUI.iconSet.streamSettingsButton);

  /// Override this method to provide custom button pressed behavior.
  void buttonPressed(BuildContext context) => presentDialog(context);

  /// Override this method to provide a custom stream settings dialog.
  /// Returns [DiveStreamSettingsDialog].
  Widget dialog(BuildContext context) {
    return DiveStreamSettingsDialog(
        serviceUrl: elements.state.streamingOutput == null
            ? null
            : elements.state.streamingOutput.serviceUrl,
        serviceKey: elements.state.streamingOutput == null
            ? null
            : elements.state.streamingOutput.serviceKey,
        onApplyCallback: onApply);
  }

  /// Override this method to provide a custom presenter.
  void presentDialog(BuildContext context) {
    DiveSideSheet.showSideSheet(
        context: context,
        rightSide: false,
        width: 500,
        builder: (BuildContext context) => dialog(context));
  }

  /// Override this method to setup custom streaming output.
  void onApply(String serviceUrl, String serviceKey) {
    if (elements == null) return;

    elements.updateState((state) {
      if (state.streamingOutput != null) {
        state.streamingOutput.serviceUrl = serviceUrl;
        state.streamingOutput.serviceKey = serviceKey;
      }
    });
  }
}

/// Signature for when settings need to be applied.
typedef DiveStreamSettingsApplyCallback = void Function(
    String serviceUrl, String serviceKey);

/// Update the video output settings.
/// Stream service URL:
/// Stream service key:
class DiveStreamSettingsDialog extends StatefulWidget {
  DiveStreamSettingsDialog(
      {Key key, this.serviceUrl, this.serviceKey, this.onApplyCallback})
      : super(key: key);

  final String serviceUrl;
  final String serviceKey;

  final DiveStreamSettingsApplyCallback onApplyCallback;

  @override
  _DiveStreamSettingsDialogState createState() =>
      _DiveStreamSettingsDialogState();
}

class _DiveStreamSettingsDialogState extends State<DiveStreamSettingsDialog> {
  TextEditingController _serviceUrl = TextEditingController();
  TextEditingController _serviceKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _useInitialState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6200EE),
        title: Text('Stream Settings'),
      ),
      body: Center(
        child: Column(children: [
          _buildConfig(context),
        ]),
      ),
    );
  }

  /// Frame rate - FPS.
  Widget _buildConfig(BuildContext context) {
    final header =
        Text('RTMP Service', style: TextStyle(fontWeight: FontWeight.bold));

    final position = Padding(
        padding: EdgeInsets.only(top: 20, left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.max,
          children: [
            header,
            Padding(padding: EdgeInsets.only(top: 20), child: Text('URL:')),
            TextField(
              controller: _serviceUrl,
            ),
            Padding(padding: EdgeInsets.only(top: 20), child: Text('Key:')),
            TextField(
              controller: _serviceKey,
            ),
          ],
        ));

    final buttons = Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(child: Text('Reset'), onPressed: () => _onReset()),
          Container(width: 15),
          ElevatedButton(
            child: Text('Apply'),
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
    _serviceUrl.text = widget.serviceUrl;
    _serviceKey.text = widget.serviceKey;
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
    widget.onApplyCallback(_serviceUrl.text, _serviceKey.text);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Properties have been applied."),
    ));
  }
}
