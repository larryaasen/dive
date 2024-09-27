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
    return MaterialApp(
      home: const CameraControllerScreen(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}

class AppTheme {
  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
      // cardColor: Colors.grey.shade800,
      // primaryColor: const Color(0xFF5747B2), // The app icon background color.
      // floatingActionButtonTheme: const FloatingActionButtonThemeData(
      //   backgroundColor: Colors.pink,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      );

  static final light = ThemeData.light(useMaterial3: true).copyWith(
      // canvasColor: Colors.red,
      // scaffoldBackgroundColor: Colors.white,
      // cardColor: Colors.white,
      // primaryColor: const Color(0xFF5747B2), // The app icon background color.
      // floatingActionButtonTheme: const FloatingActionButtonThemeData(
      //   backgroundColor: Colors.pink,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      );

  // static final pinkElevatedButton = ElevatedButton.styleFrom(
  //   foregroundColor: Colors.white,
  //   backgroundColor: Colors.pink,
  // );
}
