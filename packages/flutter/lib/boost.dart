/// The Flutter Boost framework.
///
/// To use, import `package:flutter/boost.dart`.
///
/// wangying.666@bytedance.com
///

import 'dart:ui' as engine;
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

// ignore: avoid_classes_with_only_static_members
/// See also: https://jira.bytedance.com/browse/FLUTTER-15
class Boost {
  /// All native engine flags to improve performance
  static const int _kAllFlags = 0xFF;

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

  static const int _kNotifyIdle = 1 << 7;

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
      bool extendBufferQueue,
      bool notifyIdle) {
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
    if (notifyIdle) {
      flags |= _kNotifyIdle;
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
      bool extendBufferQueue = false,
      bool notifyIdle = false}) {
    final int flags = _ensureFlags(
        false,
        disableGC,
        disableAA,
        delayFuture,
        delayPlatformMessage,
        uiMessageAtHead,
        enableWaitSwapBuffer,
        extendBufferQueue,
        notifyIdle);
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
      bool extendBufferQueue = false,
      bool notifyIdle = false}) {
    final int flags = _ensureFlags(
        finishAll,
        disableGC,
        disableAA,
        delayFuture,
        delayPlatformMessage,
        uiMessageAtHead,
        enableWaitSwapBuffer,
        extendBufferQueue,
        notifyIdle);
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

  /// 是否可以在滚动过程中利用空闲时间提前 build
  /// 外部可配置
  static bool gCanPreBuildInIdle = true;

  /// list scroll end && preloadExtent != null
  /// 外部可配置
  static bool gCanPreloadItem = false;

  /// 绘制下一帧的偏移量，数值越大越可能提前绘制，注意过大容易导致提前绘制多帧
  /// 外部可配置
  static double gIdlePreBuildOffsetScrolling = 250;

  /// 滚动结束回调，每次需要重新赋值，避免无法销毁情况
  /// 外部可配置
  static engine.NotifyIdleCallback gNotifyIdleCallbackScrollEnd;


  /// 滚动中回调，每次需要重新赋值，避免无法销毁情况
  /// 内部使用，外部不可配置
  static engine.NotifyIdleCallback localNotifyIdleCallbackScrolling;

  /// 是否正在处理 idleCallback
  /// 内部使用，外部不可配置
  static bool localIsIdleCallbacksHandling = false;

  /// 内部调用，外部不可设置
  static void ensureNotifyIdle() {
    engine.window.onNotifyIdle = (Duration duration) {
      if (gNotifyIdleCallbackScrollEnd == null && localNotifyIdleCallbackScrolling == null) {
        return;
      }
      Timeline.startSync('Boost::NotifyIdle', arguments:  {'duration': '${duration.inMilliseconds}'});
      localIsIdleCallbacksHandling = true;
      try {
        /// 如果 duration < 17ms，说明是页面滚动过程中，否则认为是页面静止状态
        if (duration.inMilliseconds < 17) {
          if (localNotifyIdleCallbackScrolling != null) {
            final engine.NotifyIdleCallback _localCallback = localNotifyIdleCallbackScrolling;
            localNotifyIdleCallbackScrolling = null;
            _localCallback(duration);
          }
        } else if (gNotifyIdleCallbackScrollEnd != null) {
          final engine.NotifyIdleCallback _localCallback = gNotifyIdleCallbackScrollEnd;
          gNotifyIdleCallbackScrollEnd = null;
          _localCallback(duration);
        }
      } catch(e, stacktrace) {
        debugPrint(stacktrace.toString());
      }
      localIsIdleCallbacksHandling = false;
      Timeline.finishSync();
    };
  }
}

