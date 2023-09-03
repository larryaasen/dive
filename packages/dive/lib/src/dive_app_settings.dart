// Copyright (c) 2023 Larry Aasen. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;
import 'package:yaml_writer/yaml_writer.dart';
import '../dive.dart';

void settingsExampleUsage() async {
  final applicationSupportDirectory = Directory('/Users/Larry/ApplicationSupport/dive/');
  final appSettings =
      DiveAppSettings(directoryPath: applicationSupportDirectory, mainFileName: 'dive_caster_settings.yml');
  final elementsNode = DiveAppSettingsNode(nodeName: 'elements', parentNode: appSettings);
  final windowNode = DiveAppSettingsNode(nodeName: 'window', parentNode: appSettings);
  appSettings.addNode(elementsNode);
  appSettings.addNode(windowNode);
  await appSettings.loadSettings();

  final streamingOutput = DiveStreamingOutput();
  streamingOutput.updateFromMap(elementsNode.settings['streaming'] as Map<String, dynamic>? ?? {});
}

/// Application Settings
class DiveAppSettings extends DiveAppSettingsNode {
  /// Create Application Settings.
  DiveAppSettings(
      {required this.directoryPath, required this.mainFileName, super.nodeName = 'root', super.parentNode});

  final Directory directoryPath;
  final String mainFileName;

  void addNode(DiveAppSettingsNode node) => _nodes.add(node);

  final _nodes = <DiveAppSettingsNode>[];

  Future<void> loadSettings() async {
    final fullPath = path.join(directoryPath.path, mainFileName);
    DiveSystemLog.message('DiveAppSettings.loadSettings: $fullPath');

    // Load the file.
    final newSettings = await _loadYamlFile(fullPath);
    newSettings.forEach((key, value) {
      if (key is String && value != null) {
        final isANode = _nodes.any((node) => node.nodeName == key);
        if (isANode) {
          final settingsNode = _nodes.firstWhere((node) => node.nodeName == key);
          if (value is Map) {
            value.forEach((key, value) {
              settingsNode.settings[key] = value;
            });
          }
        } else {
          settings[key] = value;
        }
      }
    });
  }

  /// Loads a Yaml file at [path] and returns a [Map] of the settings.
  /// Returns a [Map] containing the settings.
  /// Returns an empty [Map] when the file does not exist, or the YAML does not load.
  Future<Map> _loadYamlFile(String path) async {
    // Read YAML file
    final file = File(path);
    if (!file.existsSync()) {
      return {};
    }
    final contents = await file.readAsString();
    if (contents.isNotEmpty) {
      try {
        // Parse YAML file
        final doc = yaml.loadYaml(contents, sourceUrl: Uri.file(path));

        // Convert to a JSON string
        final rawJson = json.encode(doc);

        // Convert JSON string to a Map
        final settings = jsonDecode(rawJson);

        if (settings is Map) return settings;
        throw Exception('invalid yaml file $path');
      } on Exception catch (e) {
        throw Exception('DiveAppSettings: yaml exception $e for file $path');
      }
    }

    return {};
  }

  @override
  Future<void> saveSettings() async {
    final fullPath = path.join(directoryPath.path, mainFileName);
    if (fullPath.isEmpty) return;

    // Save the file.
    final fileSettings = <String, Object>{};
    fileSettings.addAll(settings);
    _nodes.forEach((node) {
      fileSettings[node.nodeName] = node.settings;
    });
    await saveYamlFile(fileSettings, fullPath);
  }

  Future<void> saveYamlFile(Map fileSettings, String path) async {
    try {
      final yamlWriter = YAMLWriter();
      final yamlDoc = yamlWriter.write(fileSettings);
      final file = File(path);
      file.createSync(recursive: true);
      await file.writeAsString(yamlDoc);
    } catch (e) {
      throw Exception('DiveAppSettings: yaml write exception $e for file $path');
    }
  }
}

class DiveAppSettingsNode {
  DiveAppSettingsNode({required this.nodeName, this.parentNode});

  final DiveAppSettingsNode? parentNode;

  final settings = <String, Object>{};

  final String nodeName;

  void saveSettings() {
    parentNode?.saveSettings();
  }
}
