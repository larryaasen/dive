import 'package:dive_core/dive_core.dart';
import 'package:dive_core/dive_video_info.dart';
import 'package:flutter/material.dart';
import 'dive_side_sheet.dart';

/// Signature for when a tap has occurred.
/// Return true when selection should be updated, or false to ignore tap.
typedef DiveChangeFrameRateCallback = bool Function(
    int currentIndex, int newIndex);

/// An icon button that presents the settings dialog.
class DiveSettingsButton extends StatelessWidget {
  const DiveSettingsButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: icon(), onPressed: () => buttonPressed(context));
  }

  /// Override this method to provide a custom icon.
  Icon icon() => Icon(Icons.settings);

  /// Override this method to provide custom button pressed behavior.
  void buttonPressed(BuildContext context) => presentDialog(context);

  /// Override this method to provide a custom video settings dialog.
  /// Returns [DiveVideoSettingsDialog].
  Widget dialog(BuildContext context) {
    return DiveVideoSettingsDialog();
  }

  /// Override this method to provide a custom presenter.
  void presentDialog(BuildContext context) {
    DiveSideSheet.showSideSheet(
        context: context,
        rightSide: false,
        builder: (BuildContext context) => dialog(context));
  }
}

/// Update the video output settings.
/// Resolution:
/// Frame rate:
class DiveVideoSettingsDialog extends StatefulWidget {
  DiveVideoSettingsDialog({Key key}) : super(key: key);

  @override
  _DiveVideoSettingsDialogState createState() =>
      _DiveVideoSettingsDialogState();
}

class _DiveVideoSettingsDialogState extends State<DiveVideoSettingsDialog> {
  DiveVideoInfo _videoInfo;

  @override
  void initState() {
    super.initState();
    _videoInfo = DiveVideoInfo.get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6200EE),
        title: Text('Output Settings'),
      ),
      body: Center(
        child: Column(children: [
          _buildFPS(context),
          _buildResolution(context),
        ]),
      ),
    );
  }

  /// Frame rate - FPS.
  Widget _buildFPS(BuildContext context) {
    int groupValue =
        _videoInfo != null ? DiveCoreFPS.indexOf(_videoInfo.fps) : -1;

    final header =
        Text('Frame rate', style: TextStyle(fontWeight: FontWeight.bold));
    final list = _videoInfo == null
        ? Container()
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            itemCount: DiveCoreFPS.all.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('${DiveCoreFPS.all[index].frameRate} FPS'),
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 0,
                    minLeadingWidth: 0,
                    trailing: Radio(
                      activeColor: Color(0xFF6200EE),
                      groupValue: groupValue,
                      value: index,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) async {
                        await DiveVideoInfo.changeFrameRate(
                            DiveCoreFPS.all[index]);
                        final info = DiveVideoInfo.get();
                        setState(() {
                          _videoInfo = info;
                        });
                      },
                    ),
                  ),
                  Divider(height: 0),
                ],
              );
            });
    final col = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        list,
      ],
    );
    return Align(
        alignment: Alignment.center,
        child: Container(
          width: 260,
          child: col,
          padding: EdgeInsets.only(left: 15, top: 15, right: 15, bottom: 0),
        ));
  }

  /// Output resolution.
  Widget _buildResolution(BuildContext context) {
    int groupValue = _videoInfo != null
        ? DiveCoreResolution.indexOf(_videoInfo.outputResolution)
        : -1;
    final header =
        Text('Resolution', style: TextStyle(fontWeight: FontWeight.bold));
    final list = _videoInfo == null
        ? Container()
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            itemCount: DiveCoreResolution.all.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                      title:
                          Text('${DiveCoreResolution.all[index].resolution}'),
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 20,
                      minLeadingWidth: 0,
                      trailing: Radio(
                        activeColor: Color(0xFF6200EE),
                        groupValue: groupValue,
                        value: index,
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) async {
                          // Change the output resultion, not the base resolution
                          await DiveVideoInfo.changeResolution(
                              DiveCoreResolution.all[index],
                              DiveCoreResolution.all[index]);
                          final info = DiveVideoInfo.get();
                          setState(() {
                            _videoInfo = info;
                          });
                        },
                      )),
                  Divider(height: 0),
                ],
              );
            });
    final col = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        list,
      ],
    );
    return Align(
        alignment: Alignment.center,
        child: Container(
          width: 260,
          child: col,
          padding: EdgeInsets.only(left: 15, top: 30, right: 15, bottom: 0),
        ));
  }
}
