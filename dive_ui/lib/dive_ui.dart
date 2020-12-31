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
    final state = watch(mediaSource.stateProvider.state);

    return IconButton(
      icon: Icon(state == DiveMediaState.PLAYING
          ? Icons.pause_circle_filled_outlined
          : Icons.play_circle_fill_outlined),
      tooltip: state == DiveMediaState.PLAYING ? 'Pause video' : 'Play video',
      onPressed: () {
        final stateNotifier = context.read(mediaSource.stateProvider);
        final currentState = stateNotifier.mediaState;
        currentState == DiveMediaState.PLAYING
            ? mediaSource.pause()
            : mediaSource.play();
      },
    );
  }
}

class DiveMediaStopButton extends ConsumerWidget {
  const DiveMediaStopButton({Key key, @required DiveMediaSource mediaSource})
      : mediaSource = mediaSource,
        super(key: key);

  final DiveMediaSource mediaSource;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    if (mediaSource == null) {
      return Container();
    }
    final state = watch(mediaSource.stateProvider.state);

    return IconButton(
      icon: Icon(Icons.stop_circle_outlined),
      tooltip: 'Stop video',
      onPressed:
          state != DiveMediaState.PLAYING ? null : () => mediaSource.stop(),
    );
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
        DiveMediaPlayButton(mediaSource: mediaSource),
        DiveMediaStopButton(
          mediaSource: mediaSource,
        )
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
          streamingOutput.stop().then((value) {});
        } else {
          streamingOutput.start().then((value) {});
        }
      },
    );
  }
}
