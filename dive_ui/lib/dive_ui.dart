library dive_ui;

import 'dart:io';
import 'dart:math';

import 'package:dive_core/dive_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'blocs/dive_reference_panels.dart';
import 'dive_audio_meter.dart';

export 'blocs/dive_reference_panels.dart';
export 'dive_audio_meter.dart';

class DiveUI {
  /// DiveCore and DiveUI must use the same [ProviderContainer], so it needs
  /// to be passed to DiveCore at the start.
  static void setup(BuildContext context) {
    DiveCore.providerContainer = ProviderScope.containerOf(context);
  }
}

class DiveSourceCard extends StatefulWidget {
  DiveSourceCard({this.child, this.elements, this.referencePanels, this.panel});

  final Widget child;
  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;

  @override
  _DiveSourceCardState createState() => _DiveSourceCardState();
}

class _DiveSourceCardState extends State<DiveSourceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // print("SourceCard.build: $this hovering=$_hovering");
    final stack = FocusableActionDetector(
        onShowHoverHighlight: _handleHoverHighlight,
        child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.topCenter,
            child: Stack(
              children: <Widget>[
                widget.child ?? Container(),
                if (_hovering)
                  Positioned(
                      right: 5,
                      top: 5,
                      child: DiveSourceMenu(
                          elements: widget.elements,
                          referencePanels: widget.referencePanels,
                          panel: widget.panel)),
              ],
            )));

    return stack;
  }

  void _handleHoverHighlight(bool value) {
    // print("SourceCard.onShowHoverHighlight: $this hovering=$value");

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

/// A [DivePreview] with a [DiveAudioMeter] overlay using a [DiveVolumeMeter].
class DiveMeterPreview extends DivePreview {
  DiveMeterPreview({
    TextureController controller,
    this.volumeMeter,
    Key key,
    double aspectRatio,
  }) : super(controller, key: key, aspectRatio: aspectRatio);

  /// The volume meter to display over the preview.
  final DiveVolumeMeter volumeMeter;

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);
    if (volumeMeter == null) return superWidget;

    final meterH = Positioned(
        left: 17,
        top: 5,
        right: 5,
        bottom: 4,
        child: SizedBox.expand(
            child: DiveAudioMeter(
          volumeMeter: volumeMeter,
          vertical: false,
        )));
    final meterV = Positioned(
        left: 5,
        top: 5,
        right: 5,
        bottom: 5,
        child:
            SizedBox.expand(child: DiveAudioMeter(volumeMeter: volumeMeter)));

    final stack = Stack(
      children: <Widget>[
        superWidget,
        meterV,
        meterH,
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
            ? Icons.pause_circle_filled_outlined
            : Icons.play_circle_fill_outlined,
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
      icon: Icon(
        Icons.stop_circle_outlined,
        color: iconColor,
      ),
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
          ? Icon(
              Icons.connected_tv,
              color: iconColor,
            )
          : Icon(
              Icons.live_tv,
              color: iconColor,
            ),
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

/// A Dive gear settings button.
class DiveGearButton extends StatelessWidget {
  const DiveGearButton({Key key, this.iconColor = Colors.white})
      : super(key: key);

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Ink(
          decoration: const ShapeDecoration(
            color: Colors.black12,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(Icons.settings_outlined),
            color: iconColor,
            onPressed: () {},
          ),
        ),
      ),
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

class DiveSourceMenu extends StatelessWidget {
  DiveSourceMenu({this.elements, this.referencePanels, this.panel});

  final DiveCoreElements elements;
  final DiveReferencePanelsCubit referencePanels;
  final DiveReferencePanel panel;

  @override
  Widget build(BuildContext context) {
    // id, menu text, icon, sub menu?
    final _sourceItems = elements.videoSources
        .map((source) => {
              'id': source.trackingUUID,
              'title': source.name,
              'icon': Icons.clear,
              'source': source,
              'subMenu': null,
            })
        .toList();
    final _popupItems = [
      // id, menu text, icon, sub menu?
      {
        'id': 1,
        'title': 'Clear',
        'icon': Icons.clear,
        'subMenu': null,
      },
      {
        'id': 2,
        'title': 'Select source',
        'icon': Icons.select_all,
        'subMenu': _sourceItems,
      },
    ];

    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<int>(
          child: Icon(Icons.settings_outlined,
              color: Theme.of(context).buttonColor),
          tooltip: 'Source menu',
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return _popupItems.map((Map<String, dynamic> item) {
              final child = item['subMenu'] != null
                  ? DiveSubMenu(
                      item['title'],
                      item['subMenu'],
                      onSelected: (item) {
                        if (referencePanels != null) {
                          referencePanels.assignSource(item['source'], panel);
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
            // TODO: this is not being called
            print("onSelected: $item");
            // If `clear` menu item
            if (item == 1) {
              print("onSelected: item 1");
              if (referencePanels != null) {
                print("onSelected: assign");
                referencePanels.assignSource(null, panel);
              }
            }
          },
          onCanceled: () {
            // TODO: this is not being called
            print("onCanceled");
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
        Icon(Icons.arrow_right, size: 30.0),
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
              this.onCanceled();
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ));
  }
}
