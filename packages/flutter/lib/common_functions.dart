import 'package:flutter/src/services/message_codec.dart';

@pragma('vm:entry-point')
/// Common functions interface
class CommonFunctions {

  /// normal method
  /// for example
  /// case 'GetTotalMemInfoMap':
  ///    return Performance.GetTotalMemInfoMap() as T;
  static T onMethodCall<T>(MethodCall call) {
    switch (call.method) {
      default:
        return null;
    }
  }

  /// async method
  /// for example
  /// case 'GetTotalMemInfoMap':
  ///    return Performance.GetTotalMemInfoMap() as T;
  static Future<T> onMethodCallAsync <T>(MethodCall call) async {
    switch (call.method) {
      default:
        return null;
    }
  }
}
