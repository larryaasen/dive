library dive_obslib;

export 'dive_base_obslib.dart';
export 'dive_pointer.dart';

import 'dive_base_obslib.dart';
import 'dive_ffi_obslib.dart';
// import 'dive_plugin_obslib.dart';

/// Global variable for the Dive obslib class.
/// It points to either DivePluginObslib or DiveFFIObslib.
final DiveBaseObslib obslib = DiveFFIObslib()..initialize();
// final DiveBaseObslib obslib = DivePluginObslib()..initialize();
