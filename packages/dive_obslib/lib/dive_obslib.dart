library dive_obslib;

import 'src/dive_base_obslib.dart';

export 'src/dive_base_obslib.dart';
export 'src/dive_ffi_obslib.dart';
export 'src/dive_plugin_obslib.dart';
export 'src/dive_pointer.dart';

/// Global variable for the Dive obslib class.
final DiveBaseObslib obslib = DiveBaseObslib()..initialize();
