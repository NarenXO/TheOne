import 'package:flutter/foundation.dart';

class AppLogger {
  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔵 [THEONE :: $tag] $message');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [THEONE :: $tag] $message');
    }
  }

  static void e(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔴 [THEONE :: $tag] $message');
    }
  }
}
