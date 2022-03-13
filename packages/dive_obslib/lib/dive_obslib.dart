library dive_obslib;

export 'dive_base_obslib.dart';
export 'dive_pointer.dart';
export 'dive_ffi_obslib.dart';
export 'dive_plugin_obslib.dart';

import 'dive_base_obslib.dart';

/// Global variable for the Dive obslib class.
final DiveBaseObslib obslib = DiveBaseObslib()..initialize();

/// New name examples.
final DiveBaseObslib divelib = obslib;
final DiveBaseObslib dive = obslib;
final DiveBaseObslib divebase = obslib;
final DiveBaseObslib divesys = obslib;
final DiveBaseObslib divemixer = obslib;
final DiveBaseObslib mixer = obslib;
