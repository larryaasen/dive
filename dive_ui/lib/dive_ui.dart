library dive_ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:dive_core/dive_core.dart';

class DiveUI {
  static void setup(BuildContext context) {
    // DiveCore and DiveUI must use the same [ProviderContainer], so it needs
    // to be passed to DiveCore at the start.
    DiveCore.providerContainer = ProviderScope.containerOf(context);
  }
}

/// A widget showing a preview of a video/image frame using a [Texture] widget.
class DivePreview extends StatelessWidget {
  /// Creates a preview widget for the given texture preview controller.
  const DivePreview(this.controller);

  /// The controller for the texture that the preview is shown for.
  final TextureController controller;

  @override
  Widget build(BuildContext context) {
    final texture = controller != null && controller.value.isInitialized
        ? Texture(textureId: controller.textureId)
        : Container(color: Colors.blue);

    return texture;
  }
}

class DiveMediaPlayButton extends ConsumerWidget {
  const DiveMediaPlayButton({Key key, @required DiveMediaSource mediaSource})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (mediaSource == null) {
      return Container();
    }

    final stateModel = watch(mediaSource.stateProvider.state);

    return IconButton(
      icon: Icon(stateModel.mediaState == DiveMediaState.PLAYING
          ? Icons.pause_circle_filled_outlined
          : Icons.play_circle_fill_outlined),
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
  const DiveMediaStopButton({Key key, @required this.mediaSource})
      : super(key: key);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context) {
    if (mediaSource == null) {
      return Container();
    }

    return IconButton(
      icon: Icon(Icons.stop_circle_outlined),
      tooltip: 'Stop video',
      onPressed: () async {
        print("onPressed: clicked");
        await mediaSource.stop().then((value) {
          print("stop completed");
        });
      },
    );
  }
}

class DiveMediaDuration extends ConsumerWidget {
  const DiveMediaDuration({Key key, @required this.mediaSource})
      : super(key: key);

  final DiveMediaSource mediaSource;

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
    return Text(msg);
  }
}

class DiveMediaButtonBar extends ConsumerWidget {
  const DiveMediaButtonBar({Key key, @required DiveMediaSource mediaSource})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (mediaSource == null) {
      return Container();
    }

    // final state = watch(mediaSource.stateProvider.state);

    final row = Row(
      children: [
        DiveMediaDuration(mediaSource: mediaSource),
        DiveMediaPlayButton(mediaSource: mediaSource),
        DiveMediaStopButton(mediaSource: mediaSource),
      ],
    );
    return row;
  }
}

class DiveStreamPlayButton extends ConsumerWidget {
  const DiveStreamPlayButton({
    Key key,
    @required DiveOutput streamingOutput,
  })  : streamingOutput = streamingOutput,
        super(key: key);

  final DiveOutput streamingOutput;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (streamingOutput == null) {
      return Container();
    }

    final state = watch(streamingOutput.stateProvider.state);

    return IconButton(
      icon: state == DiveOutputStreamingState.active
          ? const Icon(Icons.connected_tv)
          : const Icon(Icons.live_tv),
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
