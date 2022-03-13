import 'package:flutter/material.dart';
import 'package:dive_app/app_widget.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // We need the binding to be initialized before calling runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Configure globally for all Equatable instances via EquatableConfig
  EquatableConfig.stringify = true;

  runApp(ProviderScope(child: AppWidget()));
}
