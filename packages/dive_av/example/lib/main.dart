// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';

import 'camera_controller_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  DesktopWindow.setWindowSize(const Size(450, 700));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraControllerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
