/// The Flutter Boost framework.
///
/// To use, import `package:flutter/boost.dart`.
///
/// wangying.666@bytedance.com
///

import 'dart:ui';
import 'package:flutter/rendering.dart';

// ignore: avoid_classes_with_only_static_members
/// See also: https://jira.bytedance.com/browse/FLUTTER-15
class Boost {
  /// All native engine flags to improve performance
  static const int _kAllFlags = 0x3F;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-25
  static const int _kDisableGC = 1 << 0;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-26
  static const int _kDisableAA = 1 << 1;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-9
  static const int _kEnableWaitSwapBuffer = 1 << 2;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int _kDelayFuture = 1 << 3;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int _kDelayPlatformMessage = 1 << 4;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-80
  static const int _kEnableExtendBufferQueue = 1 << 5;

  ///
  static const Duration kMaxBoostDuration = Duration(seconds: 30);

  ///
  static const Duration _kMaxDisableGCDuration = Duration(seconds: 5);

  /// if true, will close semantics calculate when draw a frame.
  /// See also: https://jira.bytedance.com/browse/FLUTTER-3
  static bool _disabledSemantics = true;

  ///
  static bool get disabledSemantics => _disabledSemantics;

  /// If true, AnimatedBuilder will removed from the [_ModalScopeState.build]'s widget tree,
  /// then we can reuse the widgets when the transitions animation is executing.
  /// https://jira.bytedance.com/browse/FLUTTER-121
  static bool _reuseTransitionsWidget = true;

  ///
  static bool get reuseTransitionsWidget => _reuseTransitionsWidget;

  /// enable or disable semantics, reuseWidget
  static void enable({bool disableSemantics = true, bool reuseWidget = true}) {
    _disabledSemantics = disableSemantics;
    RendererBinding?.instance?.setSemanticsEnabled(!disableSemantics);
    _reuseTransitionsWidget = reuseWidget;
  }

  static int _ensureFlags(
      bool enableAll,
      bool disableGC,
      bool disableAA,
      bool waitSwapBuffer,
      bool delayFuture,
      bool delayPlatformMessage,
      bool extendBufferQueue) {
    if (enableAll) {
      return _kAllFlags.toUnsigned(16);
    }
    int flags = 0;
    if (disableGC) {
      flags |= _kDisableGC;
    }
    if (disableAA) {
      flags |= _kDisableAA;
    }
    if (waitSwapBuffer) {
      flags |= _kEnableWaitSwapBuffer;
    }
    if (delayFuture) {
      flags |= _kDelayFuture;
    }
    if (delayPlatformMessage) {
      flags |= _kDelayPlatformMessage;
    }
    if (extendBufferQueue) {
      flags |= _kEnableExtendBufferQueue;
    }
    return flags.toUnsigned(16);
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void startFromNow(Duration duration,
      {bool enabledAll = false,
      bool disableGC = false,
      bool disableAA = false,
      bool waitSwapBuffer = false,
      bool delayFuture = false,
      bool delayPlatformMessage = false,
      bool extendBufferQueue = false}) {
    final int flags = _ensureFlags(enabledAll, disableGC, disableAA,
        waitSwapBuffer, delayFuture, delayPlatformMessage, extendBufferQueue);
    if (kMaxBoostDuration < duration) {
      duration = kMaxBoostDuration;
    }
    if (enabledAll || disableGC) {
      if (duration > _kMaxDisableGCDuration) {
        duration = _kMaxDisableGCDuration;
      }
    }
    startBoost(flags, duration.inMilliseconds);
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void finishRightNow(
      {bool finishAll = false,
      bool disableGC = false,
      bool disableAA = false,
      bool waitSwapBuffer = false,
      bool delayFuture = false,
      bool delayPlatformMessage = false,
      bool extendBufferQueue = false}) {
    final int flags = _ensureFlags(finishAll, disableGC, disableAA,
        waitSwapBuffer, delayFuture, delayPlatformMessage, extendBufferQueue);
    finishBoost(flags);
  }

  /// Notify current isolate force execute gc right now.
  static void forceDartGC() {
    forceGC();
  }
}
