/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:dive_obslib/dive_obslib.dart';
// import 'package:dive_obslib/dive_ffi_obslib.dart';
// import 'package:dive_obslib/dive_plugin_obslib.dart';

void main() {
  setUp(() {
    expect(obslib, isNotNull);
  });

  tearDown(() {});

  test('testing startObs', () async {
    final rv = obslib.startObs(100, 100, 100, 100);
    expect(rv, isTrue);
  });

  test('testing createScene', () async {
    var pointer;

    pointer = obslib.createScene('trackingUUID', 'name');
    expect(pointer, isNotNull);
  });

  test('testing createScene', () async {
    var pointer;

    pointer = obslib.createMediaSource('trackingUUID', 'name');
    expect(pointer, isNotNull);
  });

  // test('testing Plugin obslib', () async {
  //   var pointer;

  //   final plugin = DivePluginObslib()..initialize();
  //   expect(plugin, isNotNull);
  //   pointer = plugin.createScene('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });

  // test('testing FFI obslib', () async {
  //   var pointer;

  //   final ffi = DiveFFIObslib()..initialize();
  //   expect(ffi, isNotNull);
  //   pointer = ffi.createScene('trackingUUID', 'name');
  //   expect(pointer, isNotNull);
  // });
}
