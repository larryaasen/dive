import 'dart:io';

import 'package:dive/dive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'dive_ui.dart';

class DiveMediaPreview extends DivePreview {
  DiveMediaPreview(this.mediaSource) : super(controller: mediaSource == null ? null : mediaSource.controller);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context) {
    final superWidget = super.build(context);

    if (mediaSource == null) return superWidget;

    final meterPosition = Rect.fromLTRB(5, 5, 5, 5);
    final meter = Positioned.fromRect(
        rect: meterPosition,
        child: SizedBox.expand(child: DiveAudioMeter(volumeMeter: mediaSource.volumeMeter)));

    final file = new File(mediaSource.settings.get('local_file'));
    String filename = path.basename(file.path);
    final filenameText = Center(child: Text(filename, style: TextStyle(color: Colors.grey, fontSize: 14)));

    final buttons = Positioned(
        right: 5, bottom: 5, child: DiveMediaButtonBar(mediaSource: mediaSource, iconColor: Colors.grey));

    final stack = Stack(
      children: <Widget>[
        superWidget,
        filenameText,
        buttons,
        meter,
      ],
    );
    final content = Container(child: stack, color: Colors.white);

    return content;
  }
}

class DiveMediaPlayButton extends ConsumerWidget {
  const DiveMediaPlayButton({Key key, @required DiveMediaSource mediaSource, this.iconColor = Colors.white})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;
  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var mediaState;
    if (mediaSource != null) {
      final stateModel = ref.watch(mediaSource.provider);
      mediaState = stateModel.mediaState;
    } else {
      mediaState = DiveMediaState.STOPPED;
    }

    return IconButton(
      icon: Icon(
        mediaState == DiveMediaState.PLAYING
            ? DiveUI.iconSet.mediaPauseButton
            : DiveUI.iconSet.mediaPlayButton,
        color: iconColor,
      ),
      tooltip: mediaState == DiveMediaState.PLAYING ? 'Pause video' : 'Play video',
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
  const DiveMediaStopButton({Key key, @required this.mediaSource, this.iconColor = Colors.white})
      : super(key: key);

  final DiveMediaSource mediaSource;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (mediaSource == null) return Container();

    return IconButton(
      icon: Icon(DiveUI.iconSet.mediaStopButton, color: iconColor),
      tooltip: 'Stop video',
      onPressed: () async {
        await mediaSource.stop().then((value) {
          print("DiveMediaStopButton: stop completed");
        });
      },
    );
  }
}

class DiveMediaDuration extends ConsumerWidget {
  const DiveMediaDuration({Key key, @required this.mediaSource, this.textColor}) : super(key: key);

  final DiveMediaSource mediaSource;
  final Color textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mediaSource == null) {
      return Container();
    }

    final stateModel = ref.watch(mediaSource.provider);
    final cur = DiveFormat.formatDuration(Duration(milliseconds: stateModel.currentTime));
    final dur = DiveFormat.formatDuration(Duration(milliseconds: stateModel.duration));
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
  const DiveMediaButtonBar({Key key, @required DiveMediaSource mediaSource, this.iconColor = Colors.white})
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
