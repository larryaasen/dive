// ignore_for_file: avoid_print
// ignore: import_of_legacy_library_into_null_safe
import 'package:dive_core/dive_core.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dive_ui/dive_ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaConsumer extends ConsumerWidget {
  const MediaConsumer({Key? key, required this.elements, required this.context}) : super(key: key);

  final DiveCoreElements elements;
  final BuildContext context;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final state = watch(elements.stateProvider.state);
    return MediaCanvas(context: context, elements: elements, state: state);
  }
}

class MediaCanvas extends StatefulWidget {
  const MediaCanvas({Key? key, required this.context, required this.elements, required this.state})
      : super(key: key);

  final DiveCoreElements elements;
  final DiveCoreElementsState state;

  final BuildContext context;

  @override
  State<MediaCanvas> createState() => _MediaCanvasState();
}

class _MediaCanvasState extends State<MediaCanvas> {
  @override
  Widget build(BuildContext context) {
    if (widget.state.videoMixes.isEmpty) {
      return Container(color: Colors.purple);
    }

    final volumeMeterSource = widget.state.audioSources.firstWhere((source) => source.volumeMeter != null);
    final volumeMeter = volumeMeterSource.volumeMeter;

    final videoMix = DiveMeterPreview(
      controller: widget.state.videoMixes[0].controller,
      volumeMeter: volumeMeter,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final cameras = DiveCameraList(
        elements: widget.elements,
        state: widget.state,
        onTap: (int currentIndex, int newIndex) {
          if (currentIndex == newIndex) return false;
          widget.elements.updateState((state) {
            // Make the new source visible
            state.currentScene.makeSourceVisible(state.videoSources[newIndex], true);

            // Make the old source not visible
            state.currentScene.makeSourceVisible(state.videoSources[currentIndex], false);
          });

          return true;
        });

    final mainContent = Row(
      children: [
        if (widget.state.videoSources.isNotEmpty) cameras,
        videoMix,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
