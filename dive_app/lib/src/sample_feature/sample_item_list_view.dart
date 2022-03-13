// ignore_for_file: avoid_print
// ignore: import_of_legacy_library_into_null_safe
import 'package:dive_core/dive_core.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dive_ui/dive_ui.dart';

import 'package:flutter/material.dart';

import '../settings/settings_view.dart';
import 'media_canvas.dart';
import 'sample_item.dart';

/// Displays a list of SampleItems.
class SampleItemListView extends StatelessWidget {
  SampleItemListView({
    Key? key,
    this.items = const [SampleItem(1), SampleItem(2), SampleItem(3)],
  }) : super(key: key);

  static const routeName = '/';

  final List<SampleItem> items;

  final _elements = DiveCoreElements();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),

      // To work with lists that may contain a large number of items, it’s best
      // to use the ListView.builder constructor.
      //
      // In contrast to the default ListView constructor, which requires
      // building all Widgets up front, the ListView.builder constructor lazily
      // builds Widgets as they’re scrolled into view.
      body: BodyWidget(elements: _elements),
    );
  }
}

class BodyWidget extends StatefulWidget {
  const BodyWidget({Key? key, required this.elements}) : super(key: key);

  final DiveCoreElements elements;

  @override
  _BodyWidgetState createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  late DiveCore _diveCore;
  late DiveCoreElements _elements;
  bool _initialized = false;

  void _initialize(BuildContext context) async {
    if (_initialized) return;

    /// DiveCore and other modules must use the same [ProviderContainer], so
    /// it needs to be passed to DiveCore at the start.
    DiveUI.setup(context);

    _elements = widget.elements;
    _diveCore = DiveCore();
    await _diveCore.setupOBS(DiveCoreResolution.HD);

    DiveScene.create('Scene 1').then((scene) {
      _elements.updateState((state) => state.currentScene = scene);

      DiveVideoMix.create().then((mix) {
        _elements.updateState((state) => state.videoMixes.add(mix));
      });

      DiveAudioSource.create('main audio').then((source) {
        setState(() {
          _elements.updateState((state) => state.audioSources.add(source));
        });
        _elements.updateState((state) => state.currentScene.addSource(source));

        DiveAudioMeterSource().create(source: source).then((volumeMeter) {
          setState(() {
            source.volumeMeter = volumeMeter;
          });
        });
      });

      DiveInputs.video().forEach((videoInput) {
        print(videoInput);
        DiveVideoSource.create(videoInput).then((source) {
          _elements.updateState((state) => state.videoSources.add(source));
          _elements.updateState((state) => state.currentScene.addSource(source));
        });
      });
    });

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _initialize(context);
    return MediaConsumer(context: context, elements: _elements);
  }
}
