import 'package:dive_ui/dive_ui.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dive_core/dive_core.dart';

void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Configure globally for all Equatable instances via EquatableConfig
  EquatableConfig.stringify = true;

  // Setup [ProviderContainer] so DiveCore and other modules use the same one
  runApp(ProviderScope(child: AppWidget()));
}

class AppWidget extends StatelessWidget {
  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dive Example 1',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dive Media Player Example'),
            actions: <Widget>[
              DiveVideoPickerButton(elements: _elements),
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
  DiveCore _diveCore;
  DiveCoreElements _elements;
  bool _initialized = false;

  void _initialize(BuildContext context) {
    if (_initialized) return;

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveCore.providerContainer = ProviderScope.containerOf(context);

    _elements = widget.elements;
    _diveCore = DiveCore();
    _diveCore.setupOBS(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.currentScene = scene);

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state.videoMixes.add(mix));
      });
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize(context);
    return MediaPlayer(context: context, elements: _elements);
  }
}

class MediaPlayer extends ConsumerWidget {
  const MediaPlayer({
    Key key,
    @required this.elements,
    @required this.context,
  }) : super(key: key);

  final DiveCoreElements elements;
  final BuildContext context;

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final state = watch(elements.stateProvider.state);
    if (state.mediaSources.length == 0 || state.videoMixes.length == 0) {
      return Container(color: Colors.purple);
    }

    final mediaButtons = Container(
        height: 40,
        color: Colors.black,
        child: SizedBox.expand(
            child: Container(
                alignment: Alignment.center,
                child: DiveMediaButtonBar(
                    iconColor: Colors.white54,
                    mediaSource: state.mediaSources[0]))));

    final videoMix = DiveMeterPreview(
      volumeMeter: state.mediaSources[0].volumeMeter,
      controller: state.videoMixes[0].controller,
      aspectRatio: DiveCoreAspectRatio.HD.ratio,
    );

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        videoMix,
        mediaButtons,
      ],
    );

    return Container(color: Colors.white, child: mainContent);
  }
}
