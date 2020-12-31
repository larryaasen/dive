import 'package:flutter/material.dart';
import 'package:dive_app/app_widget.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/all.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  EquatableConfig.stringify = true;

  runApp(ProviderScope(child: AppWidget()));
}
