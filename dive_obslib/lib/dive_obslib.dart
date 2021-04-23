library dive_obslib;

export 'dive_base_obslib.dart';
export 'dive_pointer.dart';
export 'dive_ffi_obslib.dart';
export 'dive_plugin_obslib.dart';

import 'dive_base_obslib.dart';

/// Global variable for the Dive obslib class.
/// It points to either DivePluginObslib or DiveFFIObslib.
final DiveBaseObslib obslib = DiveBaseObslib()..initialize();
