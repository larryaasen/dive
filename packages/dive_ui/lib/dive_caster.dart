// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:dive/dive.dart';
import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dive Caster Multi Camera Streaming and Recording
class DiveCasterApp extends StatelessWidget {
  const DiveCasterApp({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dive Caster',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: DiveCasterBody(elements: elements),
        drawer: Drawer(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  static openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}

class DiveCasterBody extends StatelessWidget {
  const DiveCasterBody({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        children: [
          DiveCasterHeader(elements: elements),
          Expanded(child: DiveCasterContentArea(elements: elements)),
          DiveCasterFooter(elements: elements),
        ],
      ),
    );
  }
}

class DiveCasterHeader extends StatelessWidget {
  const DiveCasterHeader({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      height: 48.0,
      child: Row(
        children: [
          IconButton(
              onPressed: () => DiveCasterApp.openDrawer(context),
              icon: Icon(Icons.menu),
              color: DiveCasterTheme.textColor),
          Spacer(),
          DiveHeaderButton(title: 'STREAM', useBlueBackground: true),
          SizedBox(width: 2.0),
          DiveHeaderRecordButton(elements: elements),
          SizedBox(width: 2.0),
          DiveHeaderButton(title: 'GRAB'),
          SizedBox(width: 2.0),
          DiveHeaderClock(),
          SizedBox(width: 2.0),
          Container(width: 40.0, color: Colors.grey.shade800),
        ],
      ),
    );
  }
}

class DiveHeaderRecordButton extends StatelessWidget {
  const DiveHeaderRecordButton({
    super.key,
    required this.elements,
  });

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        var recording = false;
        String duration = '';
        final elementsState = ref.watch(elements.provider);
        if (elementsState.recordingOutput != null) {
          final recordingState = ref.watch(elementsState.recordingOutput!.provider);
          recording = recordingState.activeState == DiveOutputRecordingActiveState.active;
          duration =
              recordingState.duration != null ? DiveFormat.formatDuration(recordingState.duration!) : '';
        }
        return DiveHeaderButton(
          title: recording ? 'RECORDING' : 'RECORD',
          subTitle: recording ? '$duration' : null,
          useRedBackground: recording,
          onPressed: () {
            final elementsState = elements.state;
            if (elementsState.recordingOutput != null) {
              final recordingState = ref.read(elementsState.recordingOutput!.provider);
              final recording = recordingState.activeState == DiveOutputRecordingActiveState.active;
              if (recording) {
                // Stop recording.
                elementsState.recordingOutput!.stop();
              } else {
                // Start recording.
                elementsState.recordingOutput!
                    .start('/Users/larry/Movies/dive', filename: 'dive1', appendTimeStamp: true);
              }
            }
          },
        );
      },
    );
  }
}

class DiveCasterFooter extends StatelessWidget {
  const DiveCasterFooter({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      height: 40.0,
      child: Row(
        children: [
          DiveHeaderIcon(icon: Icon(Icons.live_tv, color: DiveCasterTheme.textColor)),
          DiveHeaderText(text: 'Dive Caster'),
        ],
      ),
    );
  }
}

class DiveCasterContentArea extends StatelessWidget {
  const DiveCasterContentArea({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(1.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _grid()),
                  SizedBox(width: 1.0),
                  Expanded(flex: 2, child: _mix()),
                ],
              ),
            ),
            SizedBox(height: 1.0),
            Container(
                constraints: BoxConstraints(minHeight: 10.0, maxHeight: 100.0),
                color: Color.fromARGB(255, 115, 116, 114)),
          ],
        ),
      ),
    );
  }

  Widget _grid() {
    final items = List.generate(12, (index) => DivePreview());

    return GridView.count(
      primary: false,
      crossAxisCount: 3,
      childAspectRatio: DiveCoreAspectRatio.HD.ratio,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: items,
      shrinkWrap: true,
      clipBehavior: Clip.hardEdge,
    );
  }

  Widget _mix() {
    return Consumer(
      builder: (context, ref, child) {
        final elementsState = ref.watch(elements.provider);
        final controller =
            elementsState.videoMixes.isNotEmpty ? elementsState.videoMixes.first.controller : null;
        return Center(
          child: DivePreview(aspectRatio: DiveCoreAspectRatio.HD.ratio, controller: controller),
        );
      },
    );
  }
}

class DiveCasterHeaderButtons extends StatelessWidget {
  const DiveCasterHeaderButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class DiveHeaderClock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowFormatted = ref.watch(DiveCore.timeService.provider).nowFormatted;
    return SizedBox(
      width: 100.0,
      height: 36,
      child: Center(
        child: Text(nowFormatted, style: TextStyle(color: DiveCasterTheme.textColor)),
      ),
    );
  }
}

class DiveHeaderIcon extends StatelessWidget {
  const DiveHeaderIcon({super.key, required this.icon});

  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.0, right: 10.0),
      // width: 60.0,
      child: Center(child: icon),
    );
  }
}

class DiveHeaderText extends StatelessWidget {
  const DiveHeaderText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: 100.0,
      // height: 36,
      child: Center(
        child: Text(text, style: TextStyle(color: DiveCasterTheme.textColor)),
      ),
    );
  }
}

class DiveCasterTheme {
  static final textColor = Colors.grey.shade300;
  static final headerButtonTextColor = MaterialStatePropertyAll(textColor);
}

class DiveHeaderButton extends StatelessWidget {
  const DiveHeaderButton({
    super.key,
    required this.title,
    this.subTitle,
    this.useBlueBackground = false,
    this.useRedBackground = false,
    this.headerButtonTextColor,
    this.onPressed,
  });

  final String title;
  final String? subTitle;
  final bool useBlueBackground;
  final bool useRedBackground;
  final MaterialStateProperty<Color?>? headerButtonTextColor;

  /// Called when the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.0,
      height: double.infinity,
      child: Container(
        color: useBlueBackground
            ? Colors.blue.shade800
            : useRedBackground
                ? Colors.red.shade900
                : null,
        child: TextButton(
          onHover: (value) {},
          onPressed: () {
            print("pressed $title button");
            onPressed?.call();
          },
          child: subTitle == null
              ? Text(title)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title),
                    SizedBox(height: 2.0),
                    Text(subTitle!),
                  ],
                ),
          style: ButtonStyle(
            foregroundColor: headerButtonTextColor ?? DiveCasterTheme.headerButtonTextColor,
          ),
        ),
      ),
    );
  }
}
