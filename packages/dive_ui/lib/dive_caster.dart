// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'package:dive/dive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dive_record_settings_dialog.dart';
import 'dive_stream_settings_dialog.dart';
import 'dive_ui_widgets.dart';

class DiveCasterTheme {
  static final textColor = Colors.grey.shade300;
  static final headerBackgroundColor = Colors.grey.shade900;
  static final headerButtonBlueColor = Colors.blue.shade800;
  static final headerButtonBlueHoverColor = Colors.blue.shade700;
  static final headerButtonRedColor = Colors.red.shade900;
  static final headerButtonRedHoverColor = Colors.red.shade800;
  // static final headerButtonBackgroundColor = headerBackgroundColor;
  static final headerButtonHoverColor = Colors.grey.shade800;
  static final headerButtonTextColor = textColor;
}

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
      color: DiveCasterTheme.headerBackgroundColor,
      width: double.infinity,
      height: 48.0,
      child: Row(
        children: [
          IconButton(
              onPressed: () => DiveCasterApp.openDrawer(context),
              icon: Icon(Icons.menu),
              color: DiveCasterTheme.textColor),
          Spacer(),
          DiveHeaderStreamButton(elements: elements),
          SizedBox(width: 2.0),
          DiveHeaderRecordButton(elements: elements),
          SizedBox(width: 2.0),
          DiveHeaderButton(
              title: 'GRAB',
              onPressed: () {
                final sources = elements.state.videoSources;
                for (var source in sources) {
                  source.saveFrame();
                }
              }),
          SizedBox(width: 2.0),
          DiveHeaderClock(),
          // SizedBox(width: 2.0),
          // Container(width: 40.0, color: Colors.grey.shade800),
        ],
      ),
    );
  }
}

class DiveHeaderRecordButton extends StatelessWidget {
  const DiveHeaderRecordButton({super.key, required this.elements});

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
          onPressed: () async {
            final elementsState = elements.state;
            if (elementsState.recordingOutput != null) {
              final recordingState = ref.read(elementsState.recordingOutput!.provider);
              final recording = recordingState.activeState == DiveOutputRecordingActiveState.active;
              if (recording) {
                // Stop recording.
                if (elementsState.recordingOutput!.stop()) {
                  ScaffoldMessenger.maybeOf(context)!
                      .showSnackBar(SnackBar(content: Text("Record stopped.")));
                }
              } else {
                // Start recording.
                if (elementsState.recordingOutput!.start(filename: 'dive1', appendTimeStamp: true)) {
                  ScaffoldMessenger.maybeOf(context)!
                      .showSnackBar(SnackBar(content: Text("Record started.")));
                }
              }
            }
          },
          onGearPressed: () => _onGearPressed(context),
        );
      },
    );
  }

  void _onGearPressed(BuildContext context) {
    final recordingOutput = elements.state.recordingOutput;
    assert(recordingOutput != null);
    if (recordingOutput == null) return;
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: DiveRecordSettingsScreen(
              saveFolder: recordingOutput.state.folder,
              useDialog: true,
              onApplyCallback: (String directory) => _onDialogApply(context, directory),
            ),
          );
        });
  }

  void _onDialogApply(BuildContext context, String directory) {
    final recordingOutput = elements.state.recordingOutput;
    if (recordingOutput != null) {
      recordingOutput.stop();
      recordingOutput.state = recordingOutput.state.copyWith(folder: directory);

      // Save the updated settings.
      elements.saveAppSettings();
    }
    Navigator.of(context).pop();
  }
}

class DiveHeaderStreamButton extends StatelessWidget {
  const DiveHeaderStreamButton({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        var streaming = false;
        var failed = false;
        String duration = '';
        final elementsState = ref.watch(elements.provider);
        if (elementsState.streamingOutput != null) {
          final streamingState = ref.watch(elementsState.streamingOutput!.provider);
          streaming = streamingState.activeState == DiveOutputStreamingActiveState.active;
          failed = streamingState.activeState == DiveOutputStreamingActiveState.failed;
          duration =
              streamingState.duration != null ? DiveFormat.formatDuration(streamingState.duration!) : '';
        }
        return DiveHeaderButton(
          title: streaming ? 'STREAMING' : 'STREAM',
          subTitle: streaming
              ? '$duration'
              : failed
                  ? 'failure'
                  : null,
          useBlueBackground: streaming,
          useRedBackground: failed,
          trailingWidget: DiveStreamSettingsButton(elements: elements),
          onPressed: () {
            final elementsState = elements.state;
            if (elementsState.streamingOutput != null) {
              final recordingState = ref.read(elementsState.streamingOutput!.provider);
              final active = recordingState.activeState == DiveOutputStreamingActiveState.active;
              if (active) {
                // Stop streaming.
                if (elementsState.streamingOutput!.stop()) {
                  ScaffoldMessenger.maybeOf(context)!
                      .showSnackBar(SnackBar(content: Text("Stream stopped.")));
                }
              } else {
                // Start streaming.
                if (elementsState.streamingOutput!.start()) {
                  ScaffoldMessenger.maybeOf(context)!
                      .showSnackBar(SnackBar(content: Text("Stream started.")));
                }
              }
            }
          },
          onGearPressed: () => _onGearPressed(context),
        );
      },
    );
  }

  void _onGearPressed(BuildContext context) {
    assert(elements.state.streamingOutput != null);
    if (elements.state.streamingOutput == null) return;
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: DiveStreamSettingsScreen(
              service:
                  elements.state.streamingOutput == null ? null : elements.state.streamingOutput!.service,
              server: elements.state.streamingOutput == null ? null : elements.state.streamingOutput!.server,
              serviceKey:
                  elements.state.streamingOutput == null ? null : elements.state.streamingOutput!.serviceKey,
              useDialog: true,
              onApplyCallback: (DiveRTMPService service, DiveRTMPServer server, String serviceKey) =>
                  _onDialogApply(context, service, server, serviceKey),
            ),
          );
        });
  }

  void _onDialogApply(
      BuildContext context, DiveRTMPService service, DiveRTMPServer server, String serviceKey) {
    final streamingOutput = elements.state.streamingOutput;
    if (streamingOutput != null) {
      streamingOutput.stop();
      streamingOutput.service = service;
      streamingOutput.server = server;
      streamingOutput.serviceUrl = server.url;
      streamingOutput.serviceKey = serviceKey;

      // Save the updated settings.
      elements.saveAppSettings();
    }
    Navigator.of(context).pop();
  }
}

class DiveCasterFooter extends StatelessWidget {
  const DiveCasterFooter({super.key, required this.elements});

  final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DiveCasterTheme.headerBackgroundColor,
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
    final items = List.generate(12, (index) {
      return DiveSourceCard(
        // item: item,
        child: DivePreview(
            // controller: state.videoSources.length == 0 ? null : (state.videoSources.first).controller,
            controller: null,
            aspectRatio: DiveCoreAspectRatio.HD.ratio),
        elements: elements,
      );
    });

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

class DiveHeaderButton extends StatefulWidget {
  const DiveHeaderButton({
    super.key,
    required this.title,
    this.subTitle,
    this.useBlueBackground = false,
    this.useRedBackground = false,
    this.trailingWidget,
    this.onPressed,
    this.onGearPressed,
  });

  final String title;
  final String? subTitle;
  final bool useBlueBackground;
  final bool useRedBackground;
  final Widget? trailingWidget;

  /// Called when the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  /// Called when the gear button is tapped or otherwise activated. When this is null,
  /// the gear button is hidden.
  final VoidCallback? onGearPressed;

  @override
  State<DiveHeaderButton> createState() => _DiveHeaderButtonState();
}

class _DiveHeaderButtonState extends State<DiveHeaderButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      backgroundColor: widget.useBlueBackground
          ? WidgetStatePropertyAll(DiveCasterTheme.headerButtonBlueColor)
          : widget.useRedBackground
              ? WidgetStatePropertyAll(DiveCasterTheme.headerButtonRedColor)
              : WidgetStatePropertyAll(DiveCasterTheme.headerBackgroundColor),
      foregroundColor: WidgetStatePropertyAll(DiveCasterTheme.headerButtonTextColor),
      overlayColor: widget.useBlueBackground
          ? WidgetStatePropertyAll(DiveCasterTheme.headerButtonBlueHoverColor)
          : widget.useRedBackground
              ? WidgetStatePropertyAll(DiveCasterTheme.headerButtonRedHoverColor)
              : WidgetStatePropertyAll(DiveCasterTheme.headerButtonHoverColor),
      splashFactory: NoSplash.splashFactory,
    );

    final defaultTextStyle = DefaultTextStyle.of(context);
    final textStyle = TextStyle(fontSize: defaultTextStyle.style.fontSize);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.subTitle == null
            ? Text(widget.title, style: textStyle)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.title, style: textStyle),
                  SizedBox(height: 2.0),
                  Text(widget.subTitle!, style: textStyle),
                ],
              ),
        if (widget.onGearPressed != null) SizedBox(width: 16.0),
        if (widget.onGearPressed != null)
          IconButton(
            icon: Icon(DiveUI.iconSet.sourceSettingsButton),
            color: _hovering ? DiveCasterTheme.headerButtonTextColor : DiveCasterTheme.headerButtonHoverColor,
            onPressed: widget.onGearPressed,
          ),
      ],
    );

    return MouseRegion(
      onEnter: (event) {
        setState(() => _hovering = true);
      },
      onExit: (event) {
        setState(() => _hovering = false);
      },
      child: SizedBox(
        width: 160.0,
        // height: double.infinity,
        child: TextButton(
          style: style,
          onPressed: () {
            print('pressed ${widget.title} button');
            widget.onPressed?.call();
          },
          child: content,
        ),
      ),
    );
  }
}
