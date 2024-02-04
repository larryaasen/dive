// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'dart:math';

import 'package:dive/dive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dive_audio_meter.dart';
import 'dive_position_dialog.dart';
import 'dive_reference_panels.dart';
import 'dive_side_sheet.dart';

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
  IconData get recordSettingsButton => Icons.settings;
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

/// Run a Dive UI app.
void runDiveUIApp(Widget app) {
  // We need the binding to be initialized before calling runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Use [ProviderScope] so DiveCore and other modules use the same [ProviderContainer].
  runApp(ProviderScope(parent: DiveCore.providerContainer, child: app));
}

class DiveUI {
  /// The default icon set.
  static DiveIconSet get iconSet => _iconSet;
  static set iconSet(DiveIconSet iconSet) => _iconSet = iconSet;
}

/// A class to provide a [child], normally a [DivePreview], with a [DiveSourceMenu] gear button displayed
/// on top.
class DiveSourceCard extends StatefulWidget {
  /// Provides a [child], normally a [DivePreview], with a [DiveSourceMenu] gear
  /// button displayed on top.
  DiveSourceCard({required this.child, this.item, required this.elements, this.referencePanels, this.panel});

  final Widget child;

  /// Used by the [DiveSourceMenu].
  final DiveSceneItem? item;

  final DiveCoreElements elements;
  final DiveReferencePanelsCubit? referencePanels;
  final DiveReferencePanel? panel;

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
                widget.child,
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

/// A widget showing a preview of an image or video frames using a Flutter [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview({super.key, this.controller, this.aspectRatio});

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double? aspectRatio;

  /// The controller for the texture that the preview is shown for. Dive uses
  /// textures in Flutter to display raw image and video frames.
  final DiveTextureController? controller;

  @override
  Widget build(BuildContext context) {
    var texture = controller != null && controller!.isInitialized && controller!.textureId != null
        ? Texture(textureId: controller!.textureId!)
        : Container(color: Colors.blue);

    final widget = aspectRatio != null ? DiveAspectRatio(aspectRatio: aspectRatio!, child: texture) : texture;

    return widget;
  }
}

class DiveOutputButton extends ConsumerWidget {
  const DiveOutputButton({
    Key? key,
    required this.elements,
  }) : super(key: key);

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elements.provider);
    final streamingOutput = state.streamingOutput;
    if (streamingOutput == null) return Container();
    return DiveStreamPlayButton(streamingOutput: streamingOutput);
  }
}

class DiveStreamPlayButton extends ConsumerWidget {
  const DiveStreamPlayButton(
      {Key? key, required DiveStreamingOutput streamingOutput, this.iconColor = Colors.white})
      : streamingOutput = streamingOutput,
        super(key: key);

  final DiveStreamingOutput streamingOutput;
  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(streamingOutput.provider).activeState;

    return IconButton(
      icon: state == DiveOutputStreamingActiveState.active
          ? Icon(DiveUI.iconSet.streamStopButton, color: iconColor)
          : Icon(DiveUI.iconSet.streamStartButton, color: iconColor),
      tooltip: state == DiveOutputStreamingActiveState.active ? 'Stop streaming' : 'Start streaming',
      onPressed: () {
        if (state == DiveOutputStreamingActiveState.active) {
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
  /// The [aspectRatio] must be a finite number greater than zero.
  const DiveAspectRatio({super.key, required this.aspectRatio, required this.child});

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
    // The aspect ratio must be greater than 0.
    final ratio = aspectRatio > 0 ? aspectRatio : 1.0;

    return AspectRatio(aspectRatio: ratio, child: child);
  }
}

class DiveGrid extends StatelessWidget {
  const DiveGrid({
    Key? key,
    required this.aspectRatio,
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

// A class to provide a source menu.
class DiveSourceMenu extends StatefulWidget {
  /// Provides a menu with a list of selectable video sources from [elements]. It also provides a button
  /// that when tapped displays the menu.
  DiveSourceMenu({this.item, required this.elements, this.referencePanels, this.panel, this.onDisplayed});

  final DiveSceneItem? item;
  final DiveCoreElements elements;
  final DiveReferencePanelsCubit? referencePanels;
  final DiveReferencePanel? panel;
  final DiveBoolCallback? onDisplayed;

  @override
  _DiveSourceMenuState createState() => _DiveSourceMenuState();
}

class _DiveSourceMenuState extends State<DiveSourceMenu> {
  void _onClear() {
    print("_onClear");
    if (widget.referencePanels != null) {
      print("DiveSourceMenu: assign");
      widget.referencePanels!.assignSource(null, widget.panel);
    }
  }

  void _onPosition() {
    print("_onPosition");
    DiveSideSheet.showSideSheet(
        context: context,
        rightSide: false,
        builder: (BuildContext context) => DivePositionDialog(item: widget.item));
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
          child: Icon(DiveUI.iconSet.sourceSettingsButton, color: Colors.grey),
          tooltip: 'Source menu',
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            print("DiveSourceMenu: displayed");
            widget.onDisplayed?.call(true);

            return _popupItems.map((Map<String, dynamic> item) {
              final child = item['subMenu'] != null
                  ? DiveSubMenu(
                      item['title'],
                      item['subMenu'],
                      onSelected: (item) {
                        widget.referencePanels?.assignSource(item['source'] as DiveSource?, widget.panel);
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
            widget.onDisplayed?.call(false);

            final callback = _popupItems[item]['callback'] as Function?;
            callback?.call();
          },
          onCanceled: () {
            print("DiveSourceMenu.onCanceled");
            widget.onDisplayed?.call(false);
          },
        ));
  }
}

class DiveSubMenu extends StatelessWidget {
  DiveSubMenu(this.title, this.popupItems, {this.onSelected, this.onCanceled});

  final String title;
  final List<Map<String, Object?>> popupItems;

  /// Called when the user selects a value from the popup menu created by this
  /// menu.
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final void Function(Map<String, Object?> item)? onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final void Function()? onCanceled;

  @override
  Widget build(BuildContext context) {
    final mainChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title),
        Icon(DiveUI.iconSet.sourceMenuSubmenuRight, size: 30.0),
      ],
    );
    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<Map<String, Object?>>(
          child: mainChild,
          tooltip: title,
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return popupItems.map((Map<String, Object?> item) {
              return PopupMenuItem<Map<String, Object?>>(
                  key: Key('diveSubMenu_${item['id']}'),
                  value: item,
                  child: Flexible(
                      child: Row(children: <Widget>[
                    Icon(item['icon'] as IconData, color: Colors.grey),
                    Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Text(
                          item['title'].toString().substring(0, min(14, item['title'].toString().length)),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ])));
            }).toList();
          },
          onSelected: (item) {
            this.onSelected?.call(item);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          onCanceled: () {
            this.onCanceled?.call();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ));
  }
}

class DiveImagePickerButton extends StatelessWidget {
  final DiveCoreElements elements;

  DiveImagePickerButton({required this.elements});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(DiveUI.iconSet.imagePickerButton), onPressed: () => _buttonPressed(context));
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
      DiveSystemLog.message('DiveImagePickerButton: file=${file.path}', group: 'dive_ui');

      // Remove the first image source, assuming it was added here earlier.
      if (elements.state.imageSources.isNotEmpty) {
        elements.removeImageSource(elements.state.imageSources.first);
      }

      elements.addImageSource(file.path);
    });
  }
}

class DiveVideoPickerButton extends StatelessWidget {
  final DiveCoreElements elements;

  DiveVideoPickerButton({required this.elements});

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
      DiveSystemLog.message('DiveVideoPickerButton: file=${file.path}', group: 'dive_ui');

      // Remove the first media source, assuming it was added here earlier.
      if (elements.state.mediaSources.isNotEmpty) {
        elements.removeMediaSource(elements.state.mediaSources.first);
      }

      // Add the media source.
      elements.addLocalVideoMediaSource('video', file.path);
    });
  }
}

/// A widget that displays a vertical list of the video cameras.
class DiveCameraList extends StatefulWidget {
  const DiveCameraList({
    Key? key,
    required this.elements,
    required this.state,
    this.nameOnly = false,
    this.onTap,
  }) : super(key: key);

  final DiveCoreElements? elements;
  final DiveCoreElementsState state;
  final bool nameOnly;

  /// Called when the user taps this list tile.
  final DiveListTapCallback? onTap;

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
                ? Text("Camera:\n${widget.state.videoSources.toList()[index].name}")
                : DiveAspectRatio(
                    aspectRatio: DiveCoreAspectRatio.HD.ratio,
                    child: DivePreview(controller: widget.state.videoSources.toList()[index].controller));
            return Card(
                child: ListTile(
              tileColor: Colors.grey.shade900,
              selectedTileColor: Colors.grey.shade800,
              title: content,
              selected: index == _selectedIndex,
              onTap: () {
                final rv = widget.onTap?.call(_selectedIndex, index);
                if (rv != null && rv) {
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
    Key? key,
    required this.elements,
    required this.state,
    this.nameOnly = false,
    this.onTap,
  }) : super(key: key);

  final DiveCoreElements elements;
  final DiveCoreElementsState state;
  final bool nameOnly;

  /// Called when the user taps this list tile.
  final DiveListTapCallback? onTap;

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
            final vol = widget.state.audioSources.toList()[index].volumeMeter ?? null;
            final meter = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.state.audioSources.toList()[index].input?.id ?? ''),
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
              title: Text(widget.state.audioSources.toList()[index].input?.name ?? ''),
              subtitle: meter,
              selected: index == _selectedIndex,
              onTap: () {
                final rv = widget.onTap?.call(_selectedIndex, index);
                if (rv != null && rv) {
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
