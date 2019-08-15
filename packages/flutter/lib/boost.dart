/// The Flutter Boost framework.
///
/// To use, import `package:flutter/boost.dart`.
///
/// wangying.666@bytedance.com
///

import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

// ignore: avoid_classes_with_only_static_members
/// See also: https://jira.bytedance.com/browse/FLUTTER-15
class Boost {

  /// All native engine flags to improve performance
  static const int kAllFlags = 0x3F;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-25
  static const int kDisableAA = 1 << 0;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-26
  static const int kDisableGC = 1 << 1;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-9
  static const int kEnableWaitSwapBuffer = 1 << 2;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int kDelayFuture = 1 << 3;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int kDelayPlatformMessage = 1 << 4;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-80
  static const int kEnableExtendBufferQueue = 1 << 5;

  /// if true, will close semantics calculate when draw a frame.
  /// See also: https://jira.bytedance.com/browse/FLUTTER-3
  static bool _disabledSemantics = false;

  /// See also: _disabledSemantics
  static bool get disabledSemantics => _disabledSemantics;

  /// See also: _disabledSemantics
  static set disabledSemantics(bool disabled) {
    _disabledSemantics = disabled;
    RendererBinding?.instance?.setSemanticsEnabled(!disabled);
  }

  /// Can reduce the build time when execute the transit animation
  /// See also: https://jira.bytedance.com/browse/FLUTTER-121
  static void setReuseTransitionsWidget(bool reuse) {
    TransitionRoute.canReuseTransitionsWidget = reuse;
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void startNativeBoost(int flags, int millis) {
    startBoost(flags, millis);
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void finishNativeBoost(int flags) {
    finishBoost(flags);
  }

  /// Notify current isolate force execute gc right now.
  static void forceDartGC() {
    forceGC();
  }
}
