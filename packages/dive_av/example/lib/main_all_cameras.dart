// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dive_av/dive_av.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _diveAvPlugin = DiveAv();
  final _textures = <Map>[];
  final _sourceIds = <String>[];

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // Razer Kiyo Pro: 0x1421100015320e05
      // mmhmm Camera: mmhmmCameraDevice
      // FaceTime HD Camera (Built-in): 0x8020000005ac8514
      // Larry’s iPhone 13 Camera: 46363936-0000-0000-0000-000000000001

      final inputTypes = await _diveAvPlugin.inputsFromType('video');

      for (final inputType in inputTypes) {
        // Connect a texture to a video source.

        // Create a text.
        final textureId = await _diveAvPlugin.initializeTexture();

        // Create a video source.
        final sourceId = await _diveAvPlugin
            .createVideoSource(inputType.uniqueID, textureId: textureId);
        print('created video source: $sourceId');

        if (sourceId != null) {
          setState(() {
            _textures.add({'textureId': textureId, 'inputType': inputType});
            _sourceIds.add(sourceId);
          });
        }
      }

      _setupShutDown();
    } catch (e) {
      print('error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dive AV All Cameras Example'),
        ),
        body: Center(
          child: Wrap(
            runSpacing: 16.0,
            spacing: 16.0,
            children: _textures
                .map((source) =>
                    // Get a texture display widget
                    _texture(source['textureId'],
                        (source['inputType'] as DiveAVInput).localizedName))
                .toList(),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _texture(int textureId, String? name) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Texture(textureId: textureId),
          ),
          Text(name ?? ''),
          // const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  void _setupShutDown() {
    Future.delayed(const Duration(seconds: 20)).then((value) async {
      for (final sourceId in _sourceIds) {
        final rv = await _diveAvPlugin.removeSource(sourceId: sourceId);
        print('removed source: $sourceId, $rv');
      }

      for (final source in _textures) {
        final rv = await _diveAvPlugin.disposeTexture(source['textureId']);
        print('removed texture: ${source['textureId']}, $rv');
      }

      setState(() {
        _sourceIds.clear();
        _textures.clear();
      });
    });
  }
}
