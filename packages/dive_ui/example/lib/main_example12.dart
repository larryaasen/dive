import 'package:dive_ui/dive_ui.dart';
import 'package:flutter/material.dart';
import 'package:dive_core/dive_core.dart';

bool multiCamera = false;

/// Dive Example 12 - All Widgets
void main() {
  runDiveUIApp(AppWidget());
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive All Widgets Example'),
            actions: <Widget>[
              DiveStreamSettingsButton(elements: _elements),
              DiveOutputButton(elements: _elements),
            ],
          ),
          body: BodyWidget(elements: _elements),
        ));
  }
}

class BodyWidget extends StatefulWidget {
  BodyWidget({Key key, this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {}

  @override
  Widget build(BuildContext context) {
    final topics = _widgetList.map((name) => DiveTopicCard(
        richMedia:
            DiveMediaPlayButton(mediaSource: null, iconColor: Colors.black),
        headerText: name));
    return SingleChildScrollView(
        padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
        scrollDirection: Axis.vertical,
        child: Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: topics.toList(),
        ));
  }

  final List<String> _widgetList = [
    'DiveUIApp',
    'DiveSourceCard',
    'DiveMediaPreview',
    'DiveMeterPreview',
    'DivePreview',
    'DiveMediaPlayButton',
    'DiveMediaStopButton',
    'DiveMediaDuration',
    'DiveMediaButtonBar',
    'DiveOutputButton',
    'DiveStreamPlayButton',
    'DiveAspectRatio',
    'DiveGrid',
    'DiveSourceMenu',
    'DiveSubMenu',
    'DiveImagePickerButton',
    'DiveVideoPickerButton',
    'DiveCameraList',
    'DiveAudioList',
    'DiveAudioMeter',
    'DiveAudioMeterPainter',
    'DivePositionDialog',
    'DivePositionEdit',
    'DiveMoveItemEdit',
    'DiveSideSheet',
    'DiveStreamSettingsButton',
    'DiveStreamSettingsDialog',
    'DiveTopicCard'
  ];
}
