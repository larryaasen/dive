import 'package:dive/dive.dart';
import 'package:flutter/material.dart';
import 'dive_ui.dart';

/// An icon button that presents the stream settings dialog.
class DiveStreamSettingsButton extends StatelessWidget {
  const DiveStreamSettingsButton({Key? key, this.elements}) : super(key: key);

  final DiveCoreElements? elements;

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
        service: elements!.state.streamingOutput == null ? null : elements!.state.streamingOutput!.service,
        server: elements!.state.streamingOutput == null ? null : elements!.state.streamingOutput!.server,
        serviceKey:
            elements!.state.streamingOutput == null ? null : elements!.state.streamingOutput!.serviceKey,
        onApplyCallback: onApply);
  }

  /// Override this method to provide a custom presenter.
  void presentDialog(BuildContext context) {
    DiveSideSheet.showSideSheet(
        context: context, rightSide: false, width: 500, builder: (BuildContext context) => dialog(context));
  }

  /// Override this method to setup custom streaming output.
  void onApply(DiveRTMPService service, DiveRTMPServer server, String serviceKey) {
    if (elements == null) return;

    final state = elements!.state;
    if (state.streamingOutput != null) {
      state.streamingOutput!.stop();
      state.streamingOutput!.service = service;
      state.streamingOutput!.server = server;
      state.streamingOutput!.serviceUrl = server.url;
      state.streamingOutput!.serviceKey = serviceKey;
    }
  }
}

/// Signature for when settings need to be applied.
typedef DiveStreamSettingsApplyCallback = void Function(
    DiveRTMPService service, DiveRTMPServer server, String serviceKey);

/// Update the video output settings.
/// Stream service URL:
/// Stream service key:
class DiveStreamSettingsDialog extends StatefulWidget {
  DiveStreamSettingsDialog({Key? key, this.service, this.server, this.serviceKey, this.onApplyCallback})
      : super(key: key);

  final DiveRTMPService? service;
  final DiveRTMPServer? server;
  final String? serviceKey;
  final DiveStreamSettingsApplyCallback? onApplyCallback;

  @override
  _DiveStreamSettingsDialogState createState() => _DiveStreamSettingsDialogState();
}

class _DiveStreamSettingsDialogState extends State<DiveStreamSettingsDialog> {
  final DiveRTMPServices _rtmpServices = DiveRTMPServices.standard(commonNamesOnly: false);
  TextEditingController _serviceUrl = TextEditingController();
  TextEditingController _serviceKey = TextEditingController();
  String? _serviceName;
  String? _serverName;
  List<String>? _serverNames;

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

  /// RTMP Service
  Widget _buildConfig(BuildContext context) {
    final header = Text('RTMP Service', style: TextStyle(fontWeight: FontWeight.bold));

    final position = Padding(
        padding: EdgeInsets.only(top: 20, left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Padding(padding: EdgeInsets.only(top: 20), child: Text('Service:')),
            DropdownButton<String>(
              isExpanded: true,
              value: _serviceName!.isEmpty ? null : _serviceName,
              itemHeight: null,
              onChanged: (String? name) {
                if (name != null) {
                  setState(() {
                    _serviceName = name;
                    _serverNames = _getServerNames(name);
                    _serverName = _serverNames?.first;
                    _serviceUrl.text = _getUrlForServer(_serviceName, _serverName) ?? '';
                  });
                }
              },
              items: _items(_rtmpServices.serviceNames) as List<DropdownMenuItem<String>>?,
            ),
            Padding(padding: EdgeInsets.only(top: 20), child: Text('Server:')),
            DropdownButton<String>(
              isExpanded: true,
              value: _serverName!.isEmpty ? null : _serverName,
              itemHeight: null,
              onChanged: (String? name) {
                setState(() {
                  _serverName = name;
                  _serviceUrl.text = _getUrlForServer(_serviceName!, _serverName!) ?? '';
                });
              },
              items: _items(_serverNames ?? []) as List<DropdownMenuItem<String>>?,
            ),
            Padding(padding: EdgeInsets.only(top: 20), child: Text('URL:')),
            TextField(controller: _serviceUrl, readOnly: true),
            Padding(padding: EdgeInsets.only(top: 20), child: Text('Key:')),
            TextField(controller: _serviceKey),
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

  List<DropdownMenuItem> _items(List<String> names) {
    final items = names
        .map((name) => DropdownMenuItem(
            child: Padding(padding: const EdgeInsets.all(8.0), child: Text(name)), value: name))
        .toList();
    return items;
  }

  void _useInitialState() {
    // _serviceUrl.text = widget.serviceUrl;
    _serviceKey.text = widget.serviceKey ?? '';
    _serviceName = widget.service == null ? 'Twitch' : widget.service?.name;
    _serverNames = _getServerNames(_serviceName ?? '');
    _serverName = widget.server != null
        ? widget.server?.name
        : _serverNames != null
            ? _serverNames!.first
            : null;
    _serviceUrl.text = _getUrlForServer(_serviceName ?? '', _serverName ?? '') ?? '';
  }

  List<String>? _getServerNames(String serviceName) => _rtmpServices.serviceServers(serviceName);

  String? _getUrlForServer(String? serviceName, String? serverName) {
    if (serviceName == null) return null;
    final service = _rtmpServices.serviceForName(serviceName);
    final server = service != null && serverName != null ? service.serverForName(serverName) : null;
    return server?.url;
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
    if (widget.onApplyCallback == null || _serviceName == null || _serverName == null) return;
    final service = _rtmpServices.serviceForName(_serviceName!);
    if (service == null) return;
    final server = service.serverForName(_serverName!);
    if (server == null) return;
    widget.onApplyCallback?.call(service, server, _serviceKey.text);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Properties have been applied."),
    ));
  }
}
