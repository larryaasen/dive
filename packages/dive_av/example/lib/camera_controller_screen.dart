// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';
import 'dart:ui';

import 'package:dive_av/dive_av.dart';
import 'package:flutter/material.dart';
// import 'package:uvc/uvc.dart';
// import 'package:uvc_flutter/uvc_flutter.dart';

// import 'camera_settings_section.dart';

class CameraControllerScreen extends StatefulWidget {
  const CameraControllerScreen({super.key});

  @override
  State<CameraControllerScreen> createState() => _MyAppState();
}

class _MyAppState extends State<CameraControllerScreen>
    with WidgetsBindingObserver {
  final _diveAvPlugin = DiveAv();
  var _inputTypes = <DiveAVInput>[];
  DiveAVInput? _selectedInputType;
  Map? _selectedSource;
  late final AppLifecycleListener _listener;

  // UVC
  // UvcLib? _uvc;
  // UvcControl? _camera;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    WidgetsBinding.instance.addObserver(this);

    _listener = AppLifecycleListener(
      onExitRequested: () async {
        setState(() {
          _exiting = true;
        });
        // ignore: avoid_print
        print('Exiting.');
        _closeSource();
        // _uvc?.dispose();

        return AppExitResponse.exit;
      },
    );
  }

  @override
  dispose() {
    _listener.dispose();
    _removeTexture();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initPlatformState() async {
    try {
      // _uvc = UvcLib(libraryName: UvcFlutter.libusbLibraryName);

      _inputTypes = await _diveAvPlugin.inputsFromType('video');
      _selectedInputType = _inputTypes.isEmpty ? null : _inputTypes.first;

      setState(() {});

      await _setupSource();
      setState(() {});

      return;
    } catch (e) {
      // ignore: avoid_print
      print('error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey.shade200,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _exiting
              ? const Text('Exiting...')
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _dropdownRow(),
                      const SizedBox(height: 8.0),
                      _texture(),
                      const SizedBox(height: 16.0),
                      _settings(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _dropdownRow() {
    if (_inputTypes.isEmpty) {
      return const Text('Loading...');
    }
    final items = _inputTypes.map(
        (e) => DropdownMenuItem(value: e, child: Text(e.localizedName ?? '')));
    return Row(
      children: [
        const Text('Camera'),
        const SizedBox(width: 16.0),
        Expanded(
          child: DropdownButton<DiveAVInput>(
            isDense: true,
            value: _selectedInputType,
            items: items.toList(),
            onChanged: (DiveAVInput? value) {
              setState(() {
                _closeSource();
                _selectedInputType = value;
                _setupSource();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _settings() {
    return /*_camera == null
        ?*/
        const SizedBox.shrink();
    // : CameraSettingsSection(camera: _camera!);
  }

  void _closeSource() async {
    await _removeTexture();

    // _camera?.close();
    // _camera = null;
  }

  Future<void> _setupSource() async {
    if (_selectedInputType == null) {
      return;
    }

    final textureId = await _diveAvPlugin.initializeTexture();
    final sourceId = await _diveAvPlugin
        .createVideoSource(_selectedInputType!.uniqueID, textureId: textureId);
    // ignore: avoid_print
    print('dive_av: created video source: $sourceId');
    if (sourceId != null) {
      // _camera = _uvc?.control(
      //     vendorId: _selectedInputType!.vendorID,
      //     productId: _selectedInputType!.productID);
      setState(() {
        _selectedSource = {
          'textureId': textureId,
          'sourceId': sourceId,
          'inputType': _selectedInputType,
        };
      });
    }
  }

  Widget _texture() {
    if (_selectedSource == null) return const SizedBox.shrink();
    final textureId = _selectedSource!['textureId'];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: Texture(textureId: textureId),
      ),
    );
  }

  Future<void> _removeTexture() async {
    if (_selectedSource == null) return;
    final rv1 = await _diveAvPlugin.removeSource(
        sourceId: _selectedSource!['sourceId']);
    // ignore: avoid_print
    print('removed source: ${_selectedSource!['sourceId']}, $rv1');

    final rv2 =
        await _diveAvPlugin.disposeTexture(_selectedSource!['textureId']);
    // ignore: avoid_print
    print('removed texture: ${_selectedSource!['textureId']}, $rv2');

    setState(() {
      _selectedSource = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {}
  }
}
