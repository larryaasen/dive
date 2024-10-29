// Copyright (c) 2023 Larry Aasen. All rights reserved.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dive_av/dive_av.dart';
import 'package:dive_core/dive_core.dart';
import 'package:dive_widgets/dive_widgets.dart';
import 'package:flutter/material.dart';

import 'audio_simulator.dart';

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
  const DiveCasterApp({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Dive Caster',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: DiveCasterBody(),
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
  const DiveCasterBody({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: Column(
        children: [
          DiveCasterHeader(),
          Expanded(child: DiveCasterContentArea()),
          DiveCasterFooter(),
        ],
      ),
    );
  }
}

class DiveCasterHeader extends StatelessWidget {
  const DiveCasterHeader({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DiveCasterTheme.headerBackgroundColor,
      width: double.infinity,
      height: 48.0,
      child: Row(
        children: [
          IconButton(
              onPressed: () {}, // () => DiveCasterApp.openDrawer(context),
              icon: const Icon(Icons.menu),
              color: DiveCasterTheme.textColor),
          const Spacer(),
          // const DiveHeaderStreamButton(),
          // const SizedBox(width: 2.0),
          // const DiveHeaderRecordButton(),
          // const SizedBox(width: 2.0),
          // DiveHeaderButton(
          //     title: 'GRAB',
          //     onPressed: () {
          //       // final sources = elements.state.videoSources;
          //       // for (var source in sources) {
          //       //   source.saveFrame();
          //       // }
          //     }),
          // const SizedBox(width: 2.0),
          DiveHeaderClock(),
          // SizedBox(width: 2.0),
          // Container(width: 40.0, color: Colors.grey.shade800),
        ],
      ),
    );
  }
}

class DiveHeaderRecordButton extends StatelessWidget {
  const DiveHeaderRecordButton({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    // return Consumer(
    //   builder: (context, ref, child) {
    var recording = false;
    String duration = '';
    // final elementsState = ref.watch(elements.provider);
    // if (elementsState.recordingOutput != null) {
    //   final recordingState =
    //       ref.watch(elementsState.recordingOutput!.provider);
    //   recording = recordingState.activeState ==
    //       DiveOutputRecordingActiveState.active;
    //   duration = recordingState.duration != null
    //       ? DiveFormat.formatDuration(recordingState.duration!)
    //       : '';
    // }
    return DiveHeaderButton(
      title: recording ? 'RECORDING' : 'RECORD',
      subTitle: recording ? '$duration' : null,
      useRedBackground: recording,
      onPressed: () async {
        // final elementsState = elements.state;
        // if (elementsState.recordingOutput != null) {
        //   final recordingState =
        //       ref.read(elementsState.recordingOutput!.provider);
        //   final recording = recordingState.activeState ==
        //       DiveOutputRecordingActiveState.active;
        //   if (recording) {
        //     // Stop recording.
        //     if (elementsState.recordingOutput!.stop()) {
        //       ScaffoldMessenger.maybeOf(context)!.showSnackBar(
        //           const SnackBar(content: Text("Record stopped.")));
        //     }
        //   } else {
        //     // Start recording.
        //     if (elementsState.recordingOutput!
        //         .start(filename: 'dive1', appendTimeStamp: true)) {
        //       ScaffoldMessenger.maybeOf(context)!.showSnackBar(
        //           const SnackBar(content: Text("Record started.")));
        //     }
        //   }
        // }
      },
      onGearPressed: () => _onGearPressed(context),
    );
    //   },
    // );
  }

  void _onGearPressed(BuildContext context) {
    // final recordingOutput = elements.state.recordingOutput;
    // assert(recordingOutput != null);
    // if (recordingOutput == null) return;
    // showDialog(
    //     context: context,
    //     barrierDismissible: true,
    //     builder: (BuildContext context) {
    //       return SingleChildScrollView(
    //         child: DiveRecordSettingsScreen(
    //           saveFolder: recordingOutput.state.folder,
    //           useDialog: true,
    //           onApplyCallback: (String directory) =>
    //               _onDialogApply(context, directory),
    //         ),
    //       );
    //     });
  }

  void _onDialogApply(BuildContext context, String directory) {
    // final recordingOutput = elements.state.recordingOutput;
    // if (recordingOutput != null) {
    //   recordingOutput.stop();
    //   recordingOutput.state = recordingOutput.state.copyWith(folder: directory);

    //   // Save the updated settings.
    //   elements.saveAppSettings();
    // }
    Navigator.of(context).pop();
  }
}

class DiveHeaderStreamButton extends StatelessWidget {
  const DiveHeaderStreamButton({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    // return Consumer(
    //   builder: (context, ref, child) {
    var streaming = false;
    var failed = false;
    String duration = '';
    // final elementsState = ref.watch(elements.provider);
    // if (elementsState.streamingOutput != null) {
    //   final streamingState = ref.watch(elementsState.streamingOutput!.provider);
    //   streaming =
    //       streamingState.activeState == DiveOutputStreamingActiveState.active;
    //   failed =
    //       streamingState.activeState == DiveOutputStreamingActiveState.failed;
    //   duration = streamingState.duration != null
    //       ? DiveFormat.formatDuration(streamingState.duration!)
    //       : '';
    // }
    return DiveHeaderButton(
      title: streaming ? 'STREAMING' : 'STREAM',
      subTitle: streaming
          ? '$duration'
          : failed
              ? 'failure'
              : null,
      useBlueBackground: streaming,
      useRedBackground: failed,
      // trailingWidget: DiveStreamSettingsButton(elements: elements),
      onPressed: () {
        // final elementsState = elements.state;
        // if (elementsState.streamingOutput != null) {
        //   final recordingState =
        //       ref.read(elementsState.streamingOutput!.provider);
        //   final active = recordingState.activeState ==
        //       DiveOutputStreamingActiveState.active;
        //   if (active) {
        //     // Stop streaming.
        //     if (elementsState.streamingOutput!.stop()) {
        //       ScaffoldMessenger.maybeOf(context)!.showSnackBar(
        //           const SnackBar(content: Text("Stream stopped.")));
        //     }
        //   } else {
        //     // Start streaming.
        //     if (elementsState.streamingOutput!.start()) {
        //       ScaffoldMessenger.maybeOf(context)!.showSnackBar(
        //           const SnackBar(content: Text("Stream started.")));
        //     }
        //   }
        // }
      },
      onGearPressed: () => _onGearPressed(context),
    );
    //   },
    // );
  }

  void _onGearPressed(BuildContext context) {
    // assert(elements.state.streamingOutput != null);
    // if (elements.state.streamingOutput == null) return;
    // showDialog(
    //     context: context,
    //     barrierDismissible: true,
    //     builder: (BuildContext context) {
    //       return SingleChildScrollView(
    //         child: DiveStreamSettingsScreen(
    //           service: elements.state.streamingOutput == null
    //               ? null
    //               : elements.state.streamingOutput!.service,
    //           server: elements.state.streamingOutput == null
    //               ? null
    //               : elements.state.streamingOutput!.server,
    //           serviceKey: elements.state.streamingOutput == null
    //               ? null
    //               : elements.state.streamingOutput!.serviceKey,
    //           useDialog: true,
    //           onApplyCallback: (DiveRTMPService service, DiveRTMPServer server,
    //                   String serviceKey) =>
    //               _onDialogApply(context, service, server, serviceKey),
    //         ),
    //       );
    //     });
  }

  // void _onDialogApply(BuildContext context, DiveRTMPService service,
  //     DiveRTMPServer server, String serviceKey) {
  //   final streamingOutput = elements.state.streamingOutput;
  //   if (streamingOutput != null) {
  //     streamingOutput.stop();
  //     streamingOutput.service = service;
  //     streamingOutput.server = server;
  //     streamingOutput.serviceUrl = server.url;
  //     streamingOutput.serviceKey = serviceKey;

  //     // Save the updated settings.
  //     elements.saveAppSettings();
  //   }
  //   Navigator.of(context).pop();
  // }
}

class DiveCasterFooter extends StatelessWidget {
  const DiveCasterFooter({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DiveCasterTheme.headerBackgroundColor,
      width: double.infinity,
      height: 40.0,
      child: Row(
        children: [
          DiveHeaderIcon(
              icon: Icon(Icons.live_tv, color: DiveCasterTheme.textColor)),
          const DiveHeaderText(text: 'Dive Caster'),
        ],
      ),
    );
  }
}

class DiveCasterContentArea extends StatelessWidget {
  const DiveCasterContentArea({super.key});

  // final DiveCoreElements elements;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          children: [_content()],
        ),
      ),
    );
  }

  Widget _content() {
    return SimulatedAudio();
  }
}

class DiveCasterHeaderButtons extends StatelessWidget {
  const DiveCasterHeaderButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class DiveHeaderClock extends StatelessWidget {
  final _timeService = DiveTimeService();

  DiveHeaderClock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 100.0,
      height: 36,
      child: StreamBuilder(
        stream: _timeService.stream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final nowFormatted = state != null ? state.nowFormatted : '';
          return Text(
            nowFormatted,
            style: TextStyle(color: DiveCasterTheme.textColor)
                .copyWith(fontFamily: 'Menlo', fontSize: 16.0),
          );
        },
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
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
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
      foregroundColor:
          WidgetStatePropertyAll(DiveCasterTheme.headerButtonTextColor),
      overlayColor: widget.useBlueBackground
          ? WidgetStatePropertyAll(DiveCasterTheme.headerButtonBlueHoverColor)
          : widget.useRedBackground
              ? WidgetStatePropertyAll(
                  DiveCasterTheme.headerButtonRedHoverColor)
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
                  const SizedBox(height: 2.0),
                  Text(widget.subTitle!, style: textStyle),
                ],
              ),
        if (widget.onGearPressed != null) const SizedBox(width: 16.0),
        if (widget.onGearPressed != null)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: _hovering
                ? DiveCasterTheme.headerButtonTextColor
                : DiveCasterTheme.headerButtonHoverColor,
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

class SimulatedAudio extends StatefulWidget {
  SimulatedAudio({super.key});

  @override
  State<SimulatedAudio> createState() => _SimulatedAudioState();
}

class _SimulatedAudioState extends State<SimulatedAudio> {
  final _diveAvPlugin = DiveAv();
  final _sourceIds = <String>[];
  final _streamController = DiveAudioMeterStream();

  late Timer _timer;
  DiveAudioMeterValues _input = const DiveAudioMeterValues();
  final _simulator = AudioSimulator();
  double _peak = DiveAudioMeterConst.minLevel;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      // Platform messages may fail, so we use a try/catch PlatformException.
      // We also handle the message potentially returning null.
      try {
        final inputs = await _diveAvPlugin.inputsFromType('audio');

        for (final input in inputs) {
          print("input: $input");

          if (input.localizedName != "Vocaster One USB") continue;

          // Create an audio source.
          final sourceId = await _diveAvPlugin.createAudioSource(
              input.uniqueID, _streamController.audioMeterCallback);
          //     (sourceId, magnitude, peak, inputPeak) {
          //   print('magnitude: $magnitude, peak: $peak, inputPeak: $inputPeak');
          // });
          print('created audio source: $sourceId');

          if (sourceId != null) {
            setState(() {
              _sourceIds.add(sourceId);
            });
          }
          break;
        }
      } catch (e) {
        print('error $e');
      }
    });

    const updateInterval = Duration(milliseconds: 100);
    const simulationDuration = Duration(seconds: 50);

    // Start the simulation with updates every 100ms, range from -60 to 0 dB
    var magnitudeStream = _simulator.startMagnitudeSimulation(
      interval: updateInterval,
      minMagnitude: DiveAudioMeterConst.minLevel,
      maxMagnitude: DiveAudioMeterConst.maxLevel,
      initialMagnitude: DiveAudioMeterConst.minLevel,
    );

    // Listen to the simulator stream.
    magnitudeStream.listen(
      (magnitude) {
        if (magnitude > _peak) _peak = magnitude;
        final state = DiveAudioMeterValues(
          channelCount: 2,
          magnitude: [magnitude, magnitude],
          peak: [_peak, _peak],
          peakHold: const [
            DiveAudioMeterConst.minLevel,
            DiveAudioMeterConst.minLevel
          ], // const [-9.778120040893555],
          noSignal: false,
        );
        setState(() => _input = state);
        print('$magnitude $_peak');
      },
      onDone: () => print('Simulation stopped.'),
    );

    // Stop the simulation after 5 seconds
    Future.delayed(simulationDuration).then((value) => _simulator.stop());

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    _simulator.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 300,
            child: RepaintBoundary(
              child: DiveAudioMeter(
                values: DiveAudioMeterValues.noSignal(2),
                vertical: false,
              ),
            ),
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            width: 300,
            child: StreamBuilder(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  return RepaintBoundary(
                    child: DiveAudioMeter(
                      values: _input,
                      vertical: false,
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
