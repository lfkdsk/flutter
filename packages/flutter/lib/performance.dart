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
import 'package:flutter/src/painting/binding.dart';

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

  static String getHeapUsageJSON() {
    return performance.getHeapInfo();
  }

  /// Dart heap used, in KB
  static int getHeapUsed() {
    String jsonString = getHeapUsageJSON();
    final isolates = jsonDecode(jsonString);
    assert(isolates is List);
    int used = 0;
    for (var isolate in isolates) {
      used += isolate['heaps']['new']['used'];
      used += isolate['heaps']['old']['used'];
    }
    return used;
  }

  /// Dart heap capacity, in KB
  static int getHeapCapacity() {
    String jsonString = getHeapUsageJSON();
    final isolates = jsonDecode(jsonString);
    assert(isolates is List);
    int capacity = 0;
    for (var isolate in isolates) {
      capacity += isolate['heaps']['new']['capacity'];
      capacity += isolate['heaps']['old']['capacity'];
    }
    return capacity;
  }

  /// Dart heap external, in KB
  static int getHeapExternal() {
    String jsonString = getHeapUsageJSON();
    final isolates = jsonDecode(jsonString);
    assert(isolates is List);
    int externl = 0;
    for (var isolate in isolates) {
      externl += isolate['heaps']['new']['external'];
      externl += isolate['heaps']['old']['external'];
    }
    return externl;
  }

  /// Memory usage of decoded image in dart heap external, in KB
  static int getImageMemoryKB() {
    return performance.getImageMemoryUsage();
  }

  static List GetSkGraphicCacheMemoryKB() {
    return performance.getSkGraphicCacheMemoryUsage();
  }

  static List<dynamic> getEngineInitApmInfo() {
    return performance.getEngineInitApmInfo();
  }

  static Future<List> GetGrResourceCacheMemKB() {
    return performance.getGrResourceCacheMemInfo();
  }

  static Future<List> GetTotalExtMemInfoKB() {
    return performance.getTotalExtMemInfo();
  }

  static Future<Map> GetTotalMemInfoMap() async {
    String jsonString = getHeapUsageJSON();
    final isolates = jsonDecode(jsonString);

    int used = 0;
    int capacity = 0;
    int externl = 0;
    int gc_count = 0;
    int gc_time = 0;
    int gc_count_old = 0;
    int gc_time_old = 0;
    for (var isolate in isolates) {
      used += isolate['heaps']['new']['used'];
      used += isolate['heaps']['old']['used'];

      capacity += isolate['heaps']['new']['capacity'];
      capacity += isolate['heaps']['old']['capacity'];

      externl += isolate['heaps']['new']['external'];
      externl += isolate['heaps']['old']['external'];

      gc_count = isolate['heaps']['new']['gcCount'];
      gc_time = isolate['heaps']['new']['gcTime'];

      gc_count_old = isolate['heaps']['old']['gcCount'];
      gc_time_old = isolate['heaps']['old']['gcTime'];
    }


    List extMenList = await GetTotalExtMemInfoKB();

    int imageCache = PaintingBinding.instance?.imageCache?.currentSizeBytes >> 10;
    int imageLive = PaintingBinding.instance?.imageCache?.getImageLiveBytesSize() >> 10;
    return {
      'heap_capacity': capacity,
      'heap_used': used,
      'external_usage': externl,
      'image_usage': extMenList[0],
      'gpu_cache': extMenList[1],
      'gpu_cache_buddget': extMenList[2],
      'gpu_cache_purgeable': extMenList[3],
      'io_gpu_cache': extMenList[4],
      'io_gpu_cache_buddget': extMenList[5],
      'io_gpu_cache_purgeable': extMenList[6],
      'bitmap_cache': extMenList[7],
      'font_cache': extMenList[8],
      'image_filter': extMenList[9],
      'sk_malloc_mem': extMenList[10],
      'image_cache': imageCache,
      'image_live': imageLive,
      'gc_count': gc_count,
      'gc_time': gc_time,
      'gc_count_old': gc_count_old,
      'gc_time_old': gc_time_old
    };
  }
}
