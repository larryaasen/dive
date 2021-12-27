library dive_ui;

import 'dart:io';
import 'dart:math';

import 'package:dive_core/dive_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'blocs/dive_reference_panels.dart';
import 'dive_audio_meter.dart';
import 'dive_position_dialog.dart';
import 'dive_side_sheet.dart';

export 'blocs/dive_reference_panels.dart';
export 'dive_audio_meter.dart';
export 'dive_position_dialog.dart';
export 'dive_side_sheet.dart';
export 'dive_stream_settings_dialog.dart';
export 'dive_video_settings_dialog.dart';

/// Signature for a callback with a boolean value.
typedef DiveBoolCallback = void Function(bool value);

/// Signature for when a tap has occurred.
/// Return true when selection should be updated, or false to ignore tap.
typedef DiveListTapCallback = bool Function(int currentIndex, int newIndex);

/// The default icons for dive_ui widgets.
/// Override these methods to provide custom icons.
class DiveIconSet {
  IconData get imagePickerButton => Icons.add_a_photo_outlined;
  IconData get mediaPauseButton => Icons.pause_circle_filled_outlined;
  IconData get mediaPlayButton => Icons.play_circle_fill_outlined;
  IconData get mediaStopButton => Icons.stop_circle_outlined;
  IconData get settingsButton => Icons.settings;
  IconData get streamSettingsButton => Icons.settings;
  IconData get sourceMenuClear => Icons.clear;
  IconData get sourceMenuPosition => Icons.grid_on;
  IconData get sourceMenuSelect => Icons.select_all;
  IconData get sourceMenuSubmenu => Icons.clear;
  IconData get sourceMenuSubmenuRight => Icons.arrow_right;
  IconData get sourceSettingsButton => Icons.settings_outlined;
  IconData get streamStartButton => Icons.live_tv;
  IconData get streamStopButton => Icons.connected_tv;
  IconData get videoPickerButton => Icons.add_a_photo_sharp;
}

/// Setup the default icon set.
DiveIconSet _iconSet = DiveIconSet();

class DiveUI {
  /// DiveCore and DiveUI must use the same [ProviderContainer], so it needs
  /// to be passed to DiveCore at the start.
  static void setup(BuildContext context) {
    DiveCore.providerContainer = ProviderScope.containerOf(context);
  }

  /// The default icon set.
  static DiveIconSet get iconSet => _iconSet;
  static set iconSet(DiveIconSet iconSet) => _iconSet = iconSet;
}

/// Use [DiveUIApp] to setup DiveUI before the first [build] is called.
class DiveUIApp extends StatefulWidget {
  DiveUIApp({Key key, this.child}) : super(key: key);

  /// The [child] contained by the widget.
  final Widget child;

  @override
  _DiveUIAppState createState() => _DiveUIAppState();
}

class _DiveUIAppState extends State<DiveUIApp> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;

      /// DiveCore and other modules must use the same [ProviderContainer], so
      /// it needs to be passed to DiveCore at the start.
      DiveUI.setup(context);
    }
    return widget.child;
  }
}

class DiveSourceCard extends StatefulWidget {
  DiveSourceCard(
      {this.child, this.item, this.elements, this.referencePanels, this.panel});

  final Widget child;
  final DiveSceneItem item;
  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;

  @override
  _DiveSourceCardState createState() => _DiveSourceCardState();
}

class _DiveSourceCardState extends State<DiveSourceCard> {
  bool _hovering = false;
  bool _menuDisplayed = false;

  @override
  Widget build(BuildContext context) {
    final stack = FocusableActionDetector(
        onShowHoverHighlight: _handleHoverHighlight,
        child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.topCenter,
            child: Stack(
              children: <Widget>[
                widget.child ?? Container(),
                if (_hovering || _menuDisplayed)
                  Positioned(
                      right: 5,
                      top: 5,
                      child: DiveSourceMenu(
                        item: widget.item,
                        elements: widget.elements,
                        referencePanels: widget.referencePanels,
                        panel: widget.panel,
                        onDisplayed: (bool displayed) {
                          setState(() {
                            _menuDisplayed = displayed;
                          });
                        },
                      )),
              ],
            )));

    return stack;
  }

  void _handleHoverHighlight(bool value) {
    // Sometimes the hover state is invokes twice for the same value, so
    // it should be ignored if it did not change.
    if (_hovering == value) return;

    setState(() {
      _hovering = value;
    });
  }
}

@Deprecated(
    'This was helpful for a while, but not needed anymore. keep around for a little while')
class DiveSourcePreview extends StatelessWidget {
  const DiveSourcePreview(this.controller, {Key key}) : super(key: key);

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    final preview =
        DivePreview(controller, aspectRatio: DiveCoreAspectRatio.HD.ratio);
    return preview;
  }
}

class DiveMediaPreview extends DivePreview {
  DiveMediaPreview(this.mediaSource)
      : super(mediaSource == null ? null : mediaSource.controller);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);

    if (mediaSource == null) return superWidget;

    final meter = Positioned(
        left: 5,
        top: 5,
        right: 5,
        bottom: 5,
        child: SizedBox.expand(
            child: DiveAudioMeter(volumeMeter: mediaSource.volumeMeter)));

    final file = new File(mediaSource.localFile);
    String filename = path.basename(file.path);
    final camerasText = Center(
        child:
            Text(filename, style: TextStyle(color: Colors.grey, fontSize: 14)));

    final buttons = Positioned(
        right: 5,
        bottom: 5,
        child: DiveMediaButtonBar(
            mediaSource: mediaSource, iconColor: Colors.grey));

    final stack = Stack(
      children: <Widget>[
        superWidget,
        camerasText,
        buttons,
        meter,
      ],
    );
    final content = Container(child: stack, color: Colors.white);

    return content;
  }
}

/// A [DivePreview] with a [DiveAudioMeter] overlay using a [DiveAudioMeterSource].
class DiveMeterPreview extends DivePreview {
  DiveMeterPreview({
    TextureController controller,
    this.volumeMeter,
    Key key,
    double aspectRatio,
    this.meterVertical = false,
  }) : super(controller, key: key, aspectRatio: aspectRatio);

  /// The volume meter to display over the preview.
  final DiveAudioMeterSource volumeMeter;

  /// Volume meter should be displayed vertically.
  final bool meterVertical;

  static const vPos = RelativeRect.fromLTRB(5, 5, 5, 5);
  static const hPos = RelativeRect.fromLTRB(5, 5, 5, 5);

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);
    if (volumeMeter == null) return superWidget;
    final child = SizedBox.expand(
        child: DiveAudioMeter(
      volumeMeter: volumeMeter,
      vertical: meterVertical,
    ));

    final rect = meterVertical ? vPos : hPos;
    final meter = Positioned.fromRelativeRect(rect: rect, child: child);

    final stack = Stack(
      children: <Widget>[
        superWidget,
        meter,
      ],
    );
    final content = stack; // Container(child: stack, color: Colors.white);

    return content;
  }
}

/// A widget showing a preview of a video/image frame using a [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview(this.controller, {Key key, this.aspectRatio})
      : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    var texture = controller != null && controller.value.isInitialized
        ? Texture(textureId: controller.textureId)
        : Container(color: Colors.blue);

    final widget = aspectRatio != null
        ? DiveAspectRatio(aspectRatio: aspectRatio, child: texture)
        : texture;

    return widget;
  }
}

class DiveMediaPlayButton extends ConsumerWidget {
  const DiveMediaPlayButton(
      {Key key,
      @required DiveMediaSource mediaSource,
      this.iconColor = Colors.white})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;
  final Color iconColor;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (mediaSource == null) {
      return Container();
    }

    final stateModel = watch(mediaSource.stateProvider.state);

    return IconButton(
      icon: Icon(
        stateModel.mediaState == DiveMediaState.PLAYING
            ? DiveUI.iconSet.mediaPauseButton
            : DiveUI.iconSet.mediaPlayButton,
        color: iconColor,
      ),
      tooltip: stateModel.mediaState == DiveMediaState.PLAYING
          ? 'Pause video'
          : 'Play video',
      onPressed: () {
        mediaSource.getState().then((newStateModel) async {
          print("onPressed: state $newStateModel");
          switch (newStateModel.mediaState) {
            case DiveMediaState.STOPPED:
            case DiveMediaState.ENDED:
              await mediaSource.restart().then((value) {
                print("restart completed");
              });
              break;
            case DiveMediaState.PLAYING:
              mediaSource.pause().then((value) {
                print("pause completed");
              });
              break;
            case DiveMediaState.PAUSED:
              mediaSource.play().then((value) {
                print("play completed");
              });
              break;
            default:
              break;
          }
        });
      },
    );
  }
}

class DiveMediaStopButton extends StatelessWidget {
  const DiveMediaStopButton(
      {Key key, @required this.mediaSource, this.iconColor = Colors.white})
      : super(key: key);

  final DiveMediaSource mediaSource;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (mediaSource == null) {
      return Container();
    }

    return IconButton(
      icon: Icon(DiveUI.iconSet.mediaStopButton, color: iconColor),
      tooltip: 'Stop video',
      onPressed: () async {
        await mediaSource.stop().then((value) {
          print("stop completed");
        });
      },
    );
  }
}

class DiveMediaDuration extends ConsumerWidget {
  const DiveMediaDuration({Key key, @required this.mediaSource, this.textColor})
      : super(key: key);

  final DiveMediaSource mediaSource;
  final Color textColor;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (mediaSource == null) {
      return Container();
    }

    final stateModel = watch(mediaSource.stateProvider.state);
    final cur = DiveFormat.formatDuration(
        Duration(milliseconds: stateModel.currentTime));
    final dur =
        DiveFormat.formatDuration(Duration(milliseconds: stateModel.duration));
    final curWide = cur.padLeft(dur.length - cur.length);
    final msg = "$curWide / $dur";
    return Text(
      msg,
      style: TextStyle(color: textColor),
      textWidthBasis: TextWidthBasis.parent,
    );
  }
}

class DiveMediaButtonBar extends StatelessWidget {
  const DiveMediaButtonBar(
      {Key key,
      @required DiveMediaSource mediaSource,
      this.iconColor = Colors.white})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (mediaSource == null) {
      return Container();
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DiveMediaDuration(mediaSource: mediaSource, textColor: iconColor),
        DiveMediaPlayButton(mediaSource: mediaSource, iconColor: iconColor),
        DiveMediaStopButton(mediaSource: mediaSource, iconColor: iconColor),
      ],
    );
    return row;
  }
}

class DiveOutputButton extends ConsumerWidget {
  const DiveOutputButton({
    Key key,
    @required this.elements,
  }) : super(key: key);

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (elements == null) return Container();

    final state = watch(elements.stateProvider.state);
    if (state.streamingOutput == null) return Container();

    return DiveStreamPlayButton(
        streamingOutput: elements.state.streamingOutput);
  }
}

class DiveStreamPlayButton extends ConsumerWidget {
  const DiveStreamPlayButton(
      {Key key,
      @required DiveOutput streamingOutput,
      this.iconColor = Colors.white})
      : streamingOutput = streamingOutput,
        super(key: key);

  final DiveOutput streamingOutput;
  final Color iconColor;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (streamingOutput == null) {
      return Container();
    }

    final state = watch(streamingOutput.stateProvider.state);

    return IconButton(
      icon: state == DiveOutputStreamingState.active
          ? Icon(DiveUI.iconSet.streamStopButton, color: iconColor)
          : Icon(DiveUI.iconSet.streamStartButton, color: iconColor),
      tooltip: state == DiveOutputStreamingState.active
          ? 'Stop streaming'
          : 'Start streaming',
      onPressed: () {
        if (state == DiveOutputStreamingState.active) {
          streamingOutput.stop();
        } else {
          streamingOutput.start();
        }
      },
    );
  }
}

/// A widget that will size the child to a specific aspect ratio.
class DiveAspectRatio extends StatelessWidget {
  /// Creates a widget with a specific aspect ratio.
  ///
  /// The [aspectRatio] argument must be a finite number greater than zero.
  const DiveAspectRatio({
    Key key,
    @required this.aspectRatio,
    this.child,
  }) : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Wrap the AspectRatio inside an Align widget to make the AspectRatio
    // widget actually work.
    return Align(
        child: AspectRatio(
      aspectRatio: aspectRatio,
      child: child,
    ));
  }
}

class DiveGrid extends StatelessWidget {
  const DiveGrid({
    Key key,
    @required this.aspectRatio,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  /// The widgets to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      crossAxisCount: 3,
      childAspectRatio: aspectRatio,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: children,
      shrinkWrap: true,
      clipBehavior: Clip.hardEdge,
    );
  }
}

class DiveSourceMenu extends StatefulWidget {
  DiveSourceMenu(
      {this.item,
      this.elements,
      this.referencePanels,
      this.panel,
      this.onDisplayed});

  final DiveSceneItem item;
  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;
  final DiveBoolCallback onDisplayed;

  @override
  _DiveSourceMenuState createState() => _DiveSourceMenuState();
}

class _DiveSourceMenuState extends State<DiveSourceMenu> {
  void _onClear() {
    print("_onClear");
    if (widget.referencePanels != null) {
      print("DiveSourceMenu: assign");
      widget.referencePanels.assignSource(null, widget.panel);
    }
  }

  void _onPosition() {
    print("_onPosition");
    DiveSideSheet.showSideSheet(
        context: context,
        rightSide: false,
        builder: (BuildContext context) =>
            DivePositionDialog(item: widget.item));
  }

  void _onSelect() {
    print("_onSelect");
    // TODO: the menu needs to be popped.
  }

  @override
  Widget build(BuildContext context) {
    // id, menu text, icon, sub menu?
    final _sourceItems = widget.elements.state.videoSources
        .map((source) => {
              'id': source.trackingUUID,
              'title': source.name,
              'icon': DiveUI.iconSet.sourceMenuSubmenu,
              'source': source,
              'subMenu': null,
            })
        .toList();
    final _popupItems = [
      // id, menu text, icon, sub menu?
      {
        'id': 0,
        'title': 'Clear',
        'icon': DiveUI.iconSet.sourceMenuClear,
        'subMenu': null,
        'callback': _onClear,
      },
      {
        'id': 1,
        'title': 'Select source',
        'icon': DiveUI.iconSet.sourceMenuSelect,
        'subMenu': _sourceItems,
        'callback': _onSelect,
      },
      {
        'id': 2,
        'title': 'Position',
        'icon': DiveUI.iconSet.sourceMenuPosition,
        'callback': _onPosition,
      },
    ];

    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<int>(
          child: Icon(DiveUI.iconSet.sourceSettingsButton,
              color: Theme.of(context).buttonColor),
          tooltip: 'Source menu',
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            print("DiveSourceMenu: displayed");
            if (widget.onDisplayed != null) {
              widget.onDisplayed(true);
            }

            return _popupItems.map((Map<String, dynamic> item) {
              final child = item['subMenu'] != null
                  ? DiveSubMenu(
                      item['title'],
                      item['subMenu'],
                      onSelected: (item) {
                        if (widget.referencePanels != null) {
                          widget.referencePanels
                              .assignSource(item['source'], widget.panel);
                        }
                      },
                    )
                  : Text(item['title']);
              return PopupMenuItem<int>(
                key: Key('diveSourceMenu_${item['id']}'),
                value: item['id'],
                child: Row(
                  children: <Widget>[
                    Icon(item['icon'], color: Colors.grey),
                    Padding(padding: EdgeInsets.only(left: 6.0), child: child),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (int item) {
            print("DiveSourceMenu.onSelected: $item");
            if (widget.onDisplayed != null) {
              widget.onDisplayed(false);
            }

            final callback = _popupItems[item]['callback'] as Function;
            if (callback != null) {
              callback();
            }
          },
          onCanceled: () {
            print("DiveSourceMenu.onCanceled");
            if (widget.onDisplayed != null) {
              widget.onDisplayed(false);
            }
          },
        ));
  }
}

class DiveSubMenu extends StatelessWidget {
  DiveSubMenu(this.title, this.popupItems, {this.onSelected, this.onCanceled});

  final String title;
  final List<Map<String, Object>> popupItems;

  /// Called when the user selects a value from the popup menu created by this
  /// menu.
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final void Function(Map<String, Object> item) onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final void Function() onCanceled;

  @override
  Widget build(BuildContext context) {
    final mainChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title),
        // Spacer(),
        Icon(DiveUI.iconSet.sourceMenuSubmenuRight, size: 30.0),
      ],
    );
    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<Map<String, Object>>(
          child: mainChild,
          tooltip: title,
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return popupItems.map((Map<String, dynamic> item) {
              return PopupMenuItem<Map<String, Object>>(
                  key: Key('diveSubMenu_${item['id']}'),
                  value: item,
                  child: Flexible(
                      child: Row(children: <Widget>[
                    Icon(item['icon'], color: Colors.grey),
                    Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Text(
                          item['title'].toString().substring(
                              0, min(14, item['title'].toString().length)),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ])));
            }).toList();
          },
          onSelected: (item) {
            if (this.onSelected != null) {
              this.onSelected(item);
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          onCanceled: () {
            if (this.onSelected != null) {
              try {
                // TODO: Fix this exception thrown on this call:
                //   NoSuchMethodError: The method 'call' was called on null.
                this.onCanceled();
              } catch (e) {
                print("Exception in DiveSubMenu onCanceled: $e");
              }
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ));
  }
}

class DiveImagePickerButton extends StatelessWidget {
  final DiveCoreElements elements;

  DiveImagePickerButton({this.elements});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(DiveUI.iconSet.imagePickerButton),
        onPressed: () => _buttonPressed(context));
  }

  void _buttonPressed(BuildContext context) async {
    final typeGroup = XTypeGroup(label: 'images', extensions: [
      'bmp',
      'tga',
      'png',
      'jpeg',
      'jpg',
      'gif',
      'psd',
      'webp',
    ]);
    openFile(acceptedTypeGroups: [typeGroup]).then((file) {
      if (file == null) return;
      print("file=${file.path}");
      elements.addImageSource(file.path);
      // final info = DiveTransformInfo(
      //     pos: DiveVec2(140, 120),
      //     bounds: DiveVec2(1000, 560),
      //     boundsType: DiveBoundsType.SCALE_INNER);
      // item.updateTransformInfo(info);
    });
  }
}

class DiveVideoPickerButton extends StatelessWidget {
  final DiveCoreElements elements;

  DiveVideoPickerButton({this.elements});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(DiveUI.iconSet.videoPickerButton),
        onPressed: () {
          _addIconPressed();
        });
  }

  void _addIconPressed() async {
    final typeGroup = XTypeGroup(label: 'videos', extensions: ['mov', 'mp4']);
    openFile(acceptedTypeGroups: [typeGroup]).then((file) {
      if (file == null) return;
      print("file=${file.path}");
      elements.addVideoSource(file.path);
    });
  }
}

/// A widget that displays a vertical list of the video cameras.
class DiveCameraList extends StatefulWidget {
  const DiveCameraList({
    Key key,
    @required this.elements,
    @required this.state,
    this.nameOnly = false,
    this.onTap,
  }) : super(key: key);

  final DiveCoreElements elements;
  final DiveCoreElementsState state;
  final bool nameOnly;

  /// Called when the user taps this list tile.
  final DiveListTapCallback onTap;

  @override
  _DiveCameraListState createState() => _DiveCameraListState();
}

class _DiveCameraListState extends State<DiveCameraList> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        child: ListView.builder(
          itemCount: widget.state.videoSources.length,
          itemBuilder: (context, index) {
            final content = widget.nameOnly
                ? Text("Camera:\n${widget.state.videoSources[index].name}")
                : DiveAspectRatio(
                    aspectRatio: DiveCoreAspectRatio.HD.ratio,
                    child: DivePreview(
                        widget.state.videoSources[index].controller));
            return Card(
                child: ListTile(
              title: content,
              selected: index == _selectedIndex,
              onTap: () {
                bool rv = true;
                if (widget.onTap != null) {
                  rv = widget.onTap(_selectedIndex, index);
                }
                if (rv) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ));
          },
        ));
  }
}

/// A widget that displays a vertical list of the video cameras.
class DiveAudioList extends StatefulWidget {
  const DiveAudioList({
    Key key,
    @required this.elements,
    @required this.state,
    this.nameOnly = false,
    this.onTap,
  }) : super(key: key);

  final DiveCoreElements elements;
  final DiveCoreElementsState state;
  final bool nameOnly;

  /// Called when the user taps this list tile.
  final DiveListTapCallback onTap;

  @override
  _DiveAudioListState createState() => _DiveAudioListState();
}

class _DiveAudioListState extends State<DiveAudioList> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        child: ListView.builder(
          itemCount: widget.state.audioSources.length,
          itemBuilder: (context, index) {
            final vol = widget.state.audioSources[index].volumeMeter ?? null;
            final meter = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.state.audioSources[index].input.id),
                if (vol != null)
                  Container(
                      height: 20,
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      child: DiveAudioMeter(vertical: false, volumeMeter: vol))
              ],
            );

            return Card(
                child: ListTile(
              title: Text(widget.state.audioSources[index].input.name),
              subtitle: meter,
              selected: index == _selectedIndex,
              onTap: () {
                bool rv = true;
                if (widget.onTap != null) {
                  rv = widget.onTap(_selectedIndex, index);
                }
                if (rv) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ));
          },
        ));
  }
}
