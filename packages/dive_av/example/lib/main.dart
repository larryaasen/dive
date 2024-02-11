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
      // FaceTime HD Camera (Built-in): 0x8020000005ac8514

      final sourceId1 = await _diveAvPlugin.createVideoSource('0x1421100015320e05');
      print('createVideoSource: $sourceId1');

      // final sourceId2 = await _diveAvPlugin.createVideoSource('0x8020000005ac8514');
      // print('createVideoSource: $sourceId2');

      Future.delayed(const Duration(seconds: 10)).then((value) async {
        if (sourceId1 != null) {
          final rv1 = await _diveAvPlugin.removeSource(sourceId: sourceId1);
          print('removeSource: $sourceId1, $rv1');
        }
        // if (sourceId2 != null) {
        //   final rv2 = await _diveAvPlugin.removeSource(sourceId: sourceId2);
        //   print('removeSource: $sourceId2, $rv2');
        // }
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
        body: const Center(
          child: Text('Running'),
        ),
      ),
    );
  }
}
