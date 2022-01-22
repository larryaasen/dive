import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'dive_input_provider.dart';
import 'dive_input_type.dart';
import 'dive_properties.dart';
import 'dive_source.dart';
import 'dive_stream.dart';
import 'dive_system_log.dart';

class DiveImageSource extends DiveSource {
  @override
  DiveStream get frameOutput => _outputStream();

  DiveDataStreamItem? _lastStreamItem;
  bool _loadingLastStreamItem = false;

  DiveImageSource._({String? name, DiveCoreProperties? properties})
      : super(
            inputType: DiveInputType.image,
            name: name,
            properties: properties) {
    // Verify the properties
    if (properties != null) {
      final resourceName =
          properties.getString(DiveImageInputProvider.PROPERTY_RESOURCE_NAME);
      if (resourceName != null && resourceName.isNotEmpty) {
      } else {
        final filename =
            properties.getString(DiveImageInputProvider.PROPERTY_FILENAME);
        if (filename != null && filename.isNotEmpty) {
          final file = File(filename);
          file.exists().then((exists) {
            if (!exists) {
              DiveLog.message(
                  "DiveImageSource: ($name) filename does not exist: $filename");
            }
          });
        } else {
          final url = properties.getString(DiveImageInputProvider.PROPERTY_URL);
          if (url != null && url.isNotEmpty) {
            try {
              Uri.parse(url);
            } on Exception catch (e) {
              DiveLog.message(
                  "DiveImageSource: ($name) url not valid: $url, $e");
            }
          }
        }
      }
    }
    _loadData();
  }

  /// Create an image source.
  factory DiveImageSource.create(
      {String? name, DiveCoreProperties? properties}) {
    final source = DiveImageSource._(name: name, properties: properties);
    return source;
  }

  final _loadingController = StreamController<DiveDataStreamItem>.broadcast();

  DiveStream _outputStream() {
    StreamController<DiveDataStreamItem>? controller;

    Future<void> onListen() async {
      DiveLog.message("DiveImageSource: ($name) outputStream: onListen");
      if (_lastStreamItem != null) {
        controller?.add(_lastStreamItem!);
        return;
      }

      // Since we have to wait for the data to load, wait on this stream.
      _loadingController.stream.listen((DiveDataStreamItem item) {
        controller?.add(item);
      });
    }

    controller = StreamController<DiveDataStreamItem>(onListen: onListen);
    return controller.stream;
  }

  void _loadData() {
    if (properties != null && !_loadingLastStreamItem) {
      final resourceName =
          properties!.getString(DiveImageInputProvider.PROPERTY_RESOURCE_NAME);
      if (resourceName != null && resourceName.isNotEmpty) {
        _loadResourceFile(resourceName, _loadingController);
      } else {
        final filename =
            properties!.getString(DiveImageInputProvider.PROPERTY_FILENAME);
        if (filename != null && filename.isNotEmpty) {
          final file = File(filename);
          _loadingLastStreamItem = true;
          file.exists().then((exists) {
            if (exists) {
              _readFile(file, _loadingController);
            } else {
              _loadingLastStreamItem = false;
              DiveLog.message(
                  "DiveImageSource: ($name) filename does not exist: $filename");
            }
          });
        } else {
          final url =
              properties!.getString(DiveImageInputProvider.PROPERTY_URL);
          if (url != null && url.isNotEmpty) {
            _readNetworkFile(url, _loadingController);
          }
        }
      }
    }
  }

  void _loadResourceFile(
      String resourceName, StreamController<DiveDataStreamItem> controller) {
    _loadingLastStreamItem = true;
    rootBundle.load(resourceName).then((ByteData data) {
      _loadingLastStreamItem = false;
      final fileBytes = data.buffer.asUint8List();
      if (fileBytes.isNotEmpty) {
        DiveLog.message("DiveImageSource: ($name) file loaded: $resourceName");
        _lastStreamItem =
            DiveDataStreamItem(frame: DiveFrame.fromBytes(fileBytes));
        controller.add(_lastStreamItem!);
      }
    }).catchError((exception) {
      String message =
          'DiveImageSource: ($name) error while reading file $resourceName - ${exception.toString()}';
      DiveLog.message(message);
      controller.addError(message);
    });
  }

  void _readFile(File file, StreamController<DiveDataStreamItem> controller) {
    _loadingLastStreamItem = true;
    file.readAsBytes().then((fileBytes) {
      _loadingLastStreamItem = false;
      if (fileBytes.isNotEmpty) {
        DiveLog.message("DiveImageSource: ($name) file loaded: $file");
        _lastStreamItem =
            DiveDataStreamItem(frame: DiveFrame.fromBytes(fileBytes));
        controller.add(_lastStreamItem!);
      }
    }).catchError((exception) {
      String message;
      if (exception is FileSystemException &&
          exception.osError?.errorCode == 1) {
        message =
            'DiveImageSource: ($name) ${exception.osError?.message} - while reading file: ${file.path}';
      } else {
        message =
            'DiveImageSource: ($name) error while reading file ${file.path} - ${exception.toString()}';
      }
      DiveLog.message(message);
      controller.addError(message);
    });
  }

  void _readNetworkFile(
      String url, StreamController<DiveDataStreamItem> controller) {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } on Exception {
      _loadingLastStreamItem = false;
      DiveLog.message("DiveImageSource: ($name) file does not exist: $url");
      return;
    }
    _loadingLastStreamItem = true;
    http.readBytes(uri).then((fileBytes) {
      _loadingLastStreamItem = false;
      if (fileBytes.isNotEmpty) {
        DiveLog.message("DiveImageSource: ($name) file loaded: $url");
        _lastStreamItem =
            DiveDataStreamItem(frame: DiveFrame.fromBytes(fileBytes));
        controller.add(_lastStreamItem!);
      }
    }).catchError((exception) {
      String message;
      if (exception is SocketException && exception.osError?.errorCode == 1) {
        message =
            'DiveImageSource: ($name) ${exception.osError?.message} - while loading url: $url';
      } else {
        message =
            'DiveImageSource: ($name) error while loading url: $url - ${exception.toString()}';
      }
      DiveLog.message(message);
      controller.addError(message);
    });
  }
}
