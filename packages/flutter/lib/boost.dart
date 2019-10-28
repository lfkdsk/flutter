/// The Flutter Boost framework.
///
/// To use, import `package:flutter/boost.dart`.
///
/// wangying.666@bytedance.com
///

import 'dart:ui' as engine;
import 'package:flutter/rendering.dart';

// ignore: avoid_classes_with_only_static_members
/// See also: https://jira.bytedance.com/browse/FLUTTER-15
class Boost {
  /// All native engine flags to improve performance
  static const int _kAllFlags = 0x7F;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-25
  static const int _kDisableGC = 1 << 0;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-26
  static const int _kDisableAA = 1 << 1;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int _kDelayFuture = 1 << 2;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  static const int _kDelayPlatformMessage = 1 << 3;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-10
  static const int _kUiMessageAtHead = 1 << 4;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-9
  static const int _kEnableWaitSwapBuffer = 1 << 5;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-80
  static const int _kEnableExtendBufferQueue = 1 << 6;

  /// if true, will close semantics calculate when draw a frame.
  /// See also: https://jira.bytedance.com/browse/FLUTTER-3
  static bool _disabledSemantics = true;

  /// return semantics status
  static bool get disabledSemantics => _disabledSemantics;

  /// If true, AnimatedBuilder will removed from the [_ModalScopeState.build]'s widget tree,
  /// then we can reuse the widgets when the transitions animation is executing.
  /// https://jira.bytedance.com/browse/FLUTTER-121
  static bool _reuseTransitionsWidget = true;

  /// If can reuse widget while transitions executing
  static bool get reuseTransitionsWidget => _reuseTransitionsWidget;

  /// https://jira.bytedance.com/browse/FLUTTER-234
  static bool _ignoreTransitionsFirstFrameTimeCost = false;

  /// If true, will ignore first frame time cost when drive the transitions.
  static bool get ignoreTransitionsFirstFrameTimeCost => _ignoreTransitionsFirstFrameTimeCost;

  /// enable or disable semantics, reuseWidget and so on.
  static void enable({bool disableSemantics = true, bool reuseWidget = true, bool ignoreTransitionsFirstFrameTimeCost = false}) {
    _disabledSemantics = disableSemantics;
    RendererBinding?.instance?.setSemanticsEnabled(!disableSemantics);
    _reuseTransitionsWidget = reuseWidget;
    _ignoreTransitionsFirstFrameTimeCost = ignoreTransitionsFirstFrameTimeCost;
  }

  /// ensure boost flags
  static int _ensureFlags(
      bool isAll,
      bool disableGC,
      bool disableAA,
      bool delayFuture,
      bool delayPlatformMessage,
      bool uiMessageAtHead,
      bool enableWaitSwapBuffer,
      bool extendBufferQueue) {
    if (isAll) {
      return _kAllFlags.toUnsigned(16);
    }
    int flags = 0;
    if (disableGC) {
      flags |= _kDisableGC;
    }
    if (disableAA) {
      flags |= _kDisableAA;
    }
    if (delayFuture) {
      flags |= _kDelayFuture;
    }
    if (delayPlatformMessage) {
      flags |= _kDelayPlatformMessage;
    }
    if (uiMessageAtHead) {
      flags |= _kUiMessageAtHead;
    }
    if (enableWaitSwapBuffer) {
      flags |= _kEnableWaitSwapBuffer;
    }
    if (extendBufferQueue) {
      flags |= _kEnableExtendBufferQueue;
    }
    return flags.toUnsigned(16);
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void startFromNow(Duration duration,
      {bool disableGC = false,
      bool disableAA = false,
      bool delayFuture = false,
      bool delayPlatformMessage = false,
      bool uiMessageAtHead = false,
      bool enableWaitSwapBuffer = false,
      bool extendBufferQueue = false}) {
    final int flags = _ensureFlags(
        false,
        disableGC,
        disableAA,
        delayFuture,
        delayPlatformMessage,
        uiMessageAtHead,
        enableWaitSwapBuffer,
        extendBufferQueue);
    engine.startBoost(flags, duration.inMilliseconds);
  }

  /// See also: https://jira.bytedance.com/browse/FLUTTER-61
  static void finishRightNow(bool finishAll,
      {bool disableGC = false,
      bool disableAA = false,
      bool enableWaitSwapBuffer = false,
      bool delayFuture = false,
      bool delayPlatformMessage = false,
      bool uiMessageAtHead = false,
      bool extendBufferQueue = false}) {
    final int flags = _ensureFlags(
        finishAll,
        disableGC,
        disableAA,
        delayFuture,
        delayPlatformMessage,
        uiMessageAtHead,
        enableWaitSwapBuffer,
        extendBufferQueue);
    engine.finishBoost(flags);
  }

  /// Notify current isolate force execute gc right now.
  static void forceDartGC() {
    engine.forceGC();
  }

  /// preload fonts
  static void preloadFontFamilies(List<String> fontFamilies, Locale locale) {
    engine.preloadFontFamilies(fontFamilies, locale?.toString());
  }
}
