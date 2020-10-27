/// The Flutter Boost framework.
///
/// To use, import `package:flutter/boost.dart`.
///
/// wangying.666@bytedance.com
///

// @dart = 2.8

import 'dart:ui' show NotifyIdleCallback, performance;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

typedef NotifyDrawFrameCallback = void Function(
    int startBuild,
    int startLayout,
    int startPaint,
    int startSubmit,
    int endSubmit,
    dynamic extra);

// ignore: avoid_classes_with_only_static_members
/// See also: https://jira.bytedance.com/browse/FLUTTER-15
class Boost {
  static const String kBdFlutterTag = 'BDFlutter';

  /// All native engine flags to improve performance
  static const int _kAllFlags = 0xFF;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-25
  static const int _kDisableGC = 1 << 0;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-26
  @Deprecated('Removed from ByteFlutter 1.20')
  static const int _kDisableAA = 1 << 1;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  @Deprecated('Removed from ByteFlutter 1.20')
  static const int _kDelayFuture = 1 << 2;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-66
  @Deprecated('Removed from ByteFlutter 1.20')
  static const int _kDelayPlatformMessage = 1 << 3;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-10
  static const int _kUiMessageAtHead = 1 << 4;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-9
  @Deprecated('Removed from ByteFlutter 1.20')
  static const int _kEnableWaitSwapBuffer = 1 << 5;

  /// See also: https://jira.bytedance.com/browse/FLUTTER-80
  @Deprecated('Removed from ByteFlutter 1.20')
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
  static bool get ignoreTransitionsFirstFrameTimeCost =>
      _ignoreTransitionsFirstFrameTimeCost;

  /// if true, will disable mipmaps, save 1/4 GPU memory.
  static bool _disableMipmaps = false;

  /// return disable mipmaps status
  static bool get disableMipmaps => _disableMipmaps;

  /// if true, will print key debug info on release，profile and debug mode.
  static bool printKeyDebugInfoOnRelease = false;

  /// image alarm threshold (MB)
  static double imageAlarmThresholdMB = -1;

  /// skip frame when size of platform view is zero
  /// Effective only once. auto close when the window gets the correct size.
  static bool skipFrameWhenSizeIsZero = false;

  ///always skip frame when size of platform view is zero
  ///To solve the problem of redundant builds for hybrid routes
  static bool alwaysSkipFrameWhenSizeIsZero = false;

  ///will be used to control whether the AppBar uses the default SystemUiOverlayStyle or not.
  ///default value -> true
  static bool useDefaultSystemUiOverlayStyle = true;

  /// enable or disable semantics, reuseWidget and so on.
  static void enable(
      {bool disableSemantics = true,
      bool reuseWidget = true,
      bool ignoreTransitionsFirstFrameTimeCost = false}) {
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
    performance.startBoost(flags, duration.inMilliseconds);
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
    performance.finishBoost(flags);
  }

  /// Notify current isolate force execute gc right now.
  static void forceDartGC() {
    performance.forceGC();
  }

  /// preload fonts
  @Deprecated('preloadFontFamilies has been removed from ByteFlutter 1.20')
  static void preloadFontFamilies(List<String> fontFamilies, Locale locale) {
    throw 'preloadFontFamilies has been removed from ByteFlutter 1.20';
  }

  /// 滚动中回调，每次需要重新赋值，避免无法销毁情况
  static NotifyIdleCallback localNotifyIdleCallbackScrolling;

  /// 滚动结束回调，每次需要重新赋值，避免无法销毁情况
  static NotifyIdleCallback localNotifyIdleCallbackScrollEnd;

  /// 是否正在处理 idleCallback
  static bool localIsIdleCallbacksHandling = false;

  /// 一帧时间
  static const int oneFrameMicros = 16667;

  /// drawFrame cost time
  static NotifyDrawFrameCallback notifyDrawFrameCallback;

  /// 内部调用，回调赋值
  static void ensureNotifyIdle() {
    performance.onNotifyIdle = (Duration duration) {
      if (localNotifyIdleCallbackScrollEnd == null &&
          localNotifyIdleCallbackScrolling == null) {
        return;
      }
      localIsIdleCallbacksHandling = true;
      try {
        // 如果 duration < 17ms，说明是页面滚动过程中，否则认为是页面静止状态
        // 用完后即将 callback 设置为 null，避免存在多个列表泄漏的问题
        if (duration.inMicroseconds < oneFrameMicros) {
          if (localNotifyIdleCallbackScrolling != null) {
            final NotifyIdleCallback _localCallback =
                localNotifyIdleCallbackScrolling;
            localNotifyIdleCallbackScrolling = null;
            _localCallback(duration);
          }
        } else if (localNotifyIdleCallbackScrollEnd != null) {
          final NotifyIdleCallback _localCallback =
              localNotifyIdleCallbackScrollEnd;
          localNotifyIdleCallbackScrollEnd = null;
          _localCallback(duration);
        }
      } catch (e, stacktrace) {
        debugPrint(stacktrace.toString());
      }
      localIsIdleCallbacksHandling = false;
    };
  }

  /// 重置 callback，避免可能的泄漏问题
  static void resetIdleCallbacks() {
    localNotifyIdleCallbackScrolling = null;
    localNotifyIdleCallbackScrollEnd = null;
  }

  /// Disable mipmaps, save 1/4 GPU memory, used by image.
  static void disableMips(bool disable) {
    _disableMipmaps = disable;
    performance.disableMips(disable);
  }

  /// Get disable mipmaps state.
  static bool IsDisableMips() {
    return _disableMipmaps;
  }
}
