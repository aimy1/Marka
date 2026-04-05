export 'path_utils_stub.dart'
    if (dart.library.io) 'path_utils_io.dart'
    if (dart.library.html) 'path_utils_web.dart'
    if (dart.library.js_interop) 'path_utils_web.dart';
