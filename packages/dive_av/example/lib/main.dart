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
  final _textureIds = <int>[];
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

      for (var input in inputTypes) {
        final textureId = await _diveAvPlugin.initializeTexture();
        final sourceId = await _diveAvPlugin.createVideoSource(input.uniqueID,
            textureId: textureId);
        print('created video source: $sourceId');
        if (sourceId != null) {
          setState(() {
            _textureIds.add(textureId);
            _sourceIds.add(sourceId);
          });
        }
      }

      Future.delayed(const Duration(seconds: 20)).then((value) async {
        for (final sourceId in _sourceIds) {
          final rv = await _diveAvPlugin.removeSource(sourceId: sourceId);
          print('removed source: $sourceId, $rv');
        }

        for (final textureId in _textureIds) {
          final rv = await _diveAvPlugin.disposeTexture(textureId);
          print('removed texture: $textureId, $rv');
        }

        setState(() {
          _sourceIds.clear();
          _textureIds.clear();
        });
      });
    } catch (e) {
      print('error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Wrap(
            children: _textureIds.map((e) => _texture(e)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _texture(int textureId) {
    return SizedBox(
      width: 200,
      child: AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: Texture(textureId: textureId),
      ),
    );
  }
}
