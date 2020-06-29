/// The Flutter Monitor framework.
///
/// To use, import `package:flutter/performance.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

// @dart = 2.8

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show performance;

import 'package:flutter/src/performance/heap_snapshot.dart';
import 'package:flutter/src/widgets/binding.dart';

class LowMemoryObserver extends WidgetsBindingObserver {
  String outFilePath;

  LowMemoryObserver(this.outFilePath);

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    Performance.requestHeapSnapshot(outFilePath);
  }
}

@pragma("vm:entry-point")
class Performance {
  static bool _enableLMS = false;

  /// 开始栈采集
  static void startStackTraceSamples() {
    performance.startStackTraceSamples();
  }

  /// 拿到最近 microseconds（微秒） 时间段的栈采集信息{func_name:exec_count}
  static String getStackTraceSamples(int microseconds) {
    return performance.getStackTraceSamples(microseconds);
  }

  /// 停止栈采集
  static void stopStackTraceSamples() {
    performance.stopStackTraceSamples();
  }

  /// 开启低内存获取堆镜像
  static void enableDumpLowMemoryHeapSnapshot(String outFilePath) {
    if (_enableLMS) {
      return;
    }
    WidgetsBinding.instance.addObserver(LowMemoryObserver(outFilePath));
    _enableLMS = true;
  }

  /// 获取堆快照
  static bool requestHeapSnapshot(String outFilePath) {
    File outFile = File(outFilePath);
    if (!outFile.existsSync()) {
      outFile.createSync(recursive: true);
    }
    return performance.requestHeapSnapshot(outFilePath);
  }

  /// 解析堆快照
  static Future<HeapSnapshot> parseHeapSnapshot(String filePath) async {
    File file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    Uint8List datas = await file.readAsBytes();
    var snapshot = HeapSnapshot();
    await snapshot.loadProgress(datas).last;
    return snapshot;
  }
}
