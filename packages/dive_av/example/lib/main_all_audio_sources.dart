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
      final inputs = await _diveAvPlugin.inputsFromType('audio');

      for (final input in inputs) {
        print("input: $input");

        if (input.localizedName != "Vocaster One USB") continue;

        // Create an audio source.
        final sourceId = await _diveAvPlugin.createAudioSource(input.uniqueID,
            (sourceId, magnitude, peak, inputPeak) {
          print('magnitude: $magnitude, peak: $peak, inputPeak: $inputPeak');
        });
        print('created audio source: $sourceId');

        if (sourceId != null) {
          setState(() {
            _sourceIds.add(sourceId);
          });
        }
        break;
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
          title: const Text('Dive AV Audio Example'),
        ),
        body: const Center(
          child: Wrap(
            runSpacing: 16.0,
            spacing: 16.0,
            children: [],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  void _setupShutDown() {
    Future.delayed(const Duration(seconds: 120)).then((value) async {
      for (final sourceId in _sourceIds) {
        final rv = await _diveAvPlugin.removeSource(sourceId: sourceId);
        print('removed source: $sourceId, $rv');
      }

      setState(() {
        _sourceIds.clear();
      });
    });
  }
}
