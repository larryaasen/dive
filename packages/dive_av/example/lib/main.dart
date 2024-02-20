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
  int? _textureId1;
  int? _textureId2;
  int? _textureId3;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // Razer Kiyo Pro: 0x1421100015320e05
      // mmhmm Camera: mmhmmCameraDevice
      // FaceTime HD Camera (Built-in): 0x8020000005ac8514
      // Larry’s iPhone 13 Camera: 46363936-0000-0000-0000-000000000001

      final textureId1 = await _diveAvPlugin.initializeTexture();
      final textureId2 = await _diveAvPlugin.initializeTexture();
      final textureId3 = await _diveAvPlugin.initializeTexture();

      final sourceId1 = await _diveAvPlugin.createVideoSource(
          '46363936-0000-0000-0000-000000000001',
          textureId: textureId1);
      setState(() => _textureId1 = textureId1);
      print('createVideoSource: $sourceId1');

      final sourceId2 = await _diveAvPlugin
          .createVideoSource('0x1421100015320e05', textureId: textureId2);
      setState(() => _textureId2 = textureId2);
      print('createVideoSource: $sourceId2');

      final sourceId3 =
          await _diveAvPlugin.createVideoSource('-', textureId: textureId3);
      setState(() => _textureId3 = textureId3);
      print('createVideoSource: $sourceId3');

      Future.delayed(const Duration(seconds: 20)).then((value) async {
        if (sourceId1 != null) {
          final rv1 = await _diveAvPlugin.removeSource(sourceId: sourceId1);
          print('removeSource: $sourceId1, $rv1');
        }
        if (sourceId2 != null) {
          final rv2 = await _diveAvPlugin.removeSource(sourceId: sourceId2);
          print('removeSource: $sourceId2, $rv2');
        }
        if (sourceId3 != null) {
          final rv3 = await _diveAvPlugin.removeSource(sourceId: sourceId3);
          print('removeSource: $sourceId3, $rv3');
        }
        setState(() {
          _textureId1 = null;
          _textureId2 = null;
          _textureId3 = null;
        });
      });
    } catch (e) {
      print('error');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: _textureId1 == null
              ? const Text('Running')
              : Wrap(
                  children: [
                    if (_textureId1 != null) _texture(_textureId1!),
                    const SizedBox(width: 20, height: 20),
                    if (_textureId2 != null) _texture(_textureId2!),
                    const SizedBox(width: 20, height: 20),
                    if (_textureId3 != null) _texture(_textureId3!),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _texture(int textureId) {
    return SizedBox(
      width: 200,
      height: 100,
      child: Texture(textureId: textureId),
    );
  }
}
