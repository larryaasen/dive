library dive_ui;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:dive_core/dive_core.dart';

class DiveUI {
  /// DiveCore and DiveUI must use the same [ProviderContainer], so it needs
  /// to be passed to DiveCore at the start.
  static void setup(BuildContext context) {
    DiveCore.providerContainer = ProviderScope.containerOf(context);
  }
}

class DiveSourceCard extends StatefulWidget {
  final Widget child;

  DiveSourceCard({this.child});

  @override
  _DiveSourceCardState createState() => _DiveSourceCardState();
}

class _DiveSourceCardState extends State<DiveSourceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    print("SourceCard.build: $this hovering=$_hovering");
    final stack = FocusableActionDetector(
        onShowHoverHighlight: _handleHoverHighlight,
        child: Container(
            // color: Colors.red,
            alignment: Alignment.topCenter,
            child: Stack(
              children: <Widget>[
                widget.child ?? Container(),
                if (_hovering)
                  Positioned(right: 5, top: 5, child: DiveGearButton()),
              ],
            )));

    final card = Card(elevation: 10, child: stack);
    // return card;

    // This Padding breaks the aspect ratio inside of Card (widget.child)
    return Padding(
        padding: EdgeInsets.only(
            left: 0,
            top: 0,
            bottom: 15,
            right: 15), // need padding for the drop shadow
        child: card);
  }

  void _handleHoverHighlight(bool value) {
    print("SourceCard.onShowHoverHighlight: $this hovering=$value");

    // Sometimes the hover state is invokes twice for the same value, so
    // it should be ignored if it did not change.
    if (_hovering == value) return;

    setState(() {
      _hovering = value;
    });
  }
}

class MediaPreview extends DivePreview {
  MediaPreview(this.mediaSource)
      : super(mediaSource == null ? null : mediaSource.controller);

  // /// The controller for the texture that the preview is shown for.
  // final TextureController controller;

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);

    if (mediaSource == null) return superWidget;
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
      ],
    );

    return stack;
  }
}

/// A widget showing a preview of a video/image frame using a [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview(this.controller, {this.aspectRatio});

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

    if (aspectRatio != null) {
      texture = DiveAspectRatio(aspectRatio: aspectRatio, child: texture);
    }

    return texture;
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
        // TODO: sometimes onPressed is not called
        print("onPressed: clicked");
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
    final msg = "$cur / $dur";
    return Text(
      msg,
      style: TextStyle(color: textColor),
    );
  }
}

class DiveMediaButtonBar extends ConsumerWidget {
  const DiveMediaButtonBar(
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

    // final state = watch(mediaSource.stateProvider.state);

    final row = Row(
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
            tooltip: 'Gear',
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
      crossAxisCount: 4,
      childAspectRatio: aspectRatio,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: children,
      shrinkWrap: true,
      clipBehavior: Clip.hardEdge,
    );
  }
}
