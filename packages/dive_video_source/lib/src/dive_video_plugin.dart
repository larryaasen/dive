import 'dart:async';
import 'dart:typed_data';

import 'package:dive/dive.dart';
import 'package:flutter/services.dart';

class DiveVideoPlugin {
  static const String _channelName = 'divekit.dev/dive_video_source';
  static const String _methodGetInputsFromType = 'getInputsFromType';
  static const String _methodCreateVideoSource = 'createVideoSource';
  static const String _channelNameCall =
      'divekit.dev/dive_video_source/callback';

  static const MethodChannel _channel = MethodChannel(_channelName);

  // Get a list of inputs for this type.
  Future<List<DiveInput>?> inputsListFromType(DiveInputType type) async {
    final List<dynamic>? inputs = await _channel.invokeMethod<List<dynamic>>(
        _methodGetInputsFromType, {'type_id': type.name});
    return inputs
        ?.map((input) {
          input['type'] = type;
          return input;
        })
        .map(DiveInput.fromMap)
        .whereType<DiveInput>()
        .toList();
  }

  Future<MethodChannel?> createVideoSource(
      DiveInput input,
      void Function(int width, int height, Uint8List bytes, int linesize)
          onFrame) {
    final callbackChannelName = _channelNameCall + '.' + input.id;
    return _channel.invokeMethod<bool>(_methodCreateVideoSource, {
      'input_id': input.id,
      'callback_channel_name': callbackChannelName,
    }).then((bool? result) {
      if (result != null && result) {
        return setupChannelCallback(callbackChannelName, 'frame', onFrame);
      }
      return null;
    });
  }

  // Setup the callback for the video frames.
  MethodChannel setupChannelCallback(
      String channelName,
      String methodName,
      void Function(int width, int height, Uint8List bytes, int linesize)
          onFrame) {
    // Setup a method channel to receive the callback.
    final channel = MethodChannel(channelName);

    channel.setMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == methodName) {
        final data = methodCall.arguments['data'];
        final width = methodCall.arguments['width'];
        final height = methodCall.arguments['height'];
        final linesize = methodCall.arguments['linesize'];
        if (data != null &&
            width != null &&
            height != null &&
            linesize != null) {
          onFrame(0, 0, data, linesize);
          return "processed";
        }
        return "no processed";
      }
    });
    return channel;
  }
}
