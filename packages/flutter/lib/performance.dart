/// The Flutter Monitor framework.
///
/// To use, import `package:flutter/performance.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as engine;

import 'package:flutter/src/performance/heap_snapshot.dart';

typedef void LowMemoryCallback();

@pragma("vm:entry-point")
class Performance {

  static List<LowMemoryCallback> _lowMemoryCallbacks = [];

  /// 开始栈采集
  static void startStackTraceSamples(){
    engine.startStackTraceSamples();
  }

  /// 拿到最近 microseconds（微秒） 时间段的栈采集信息{func_name:exec_count}
  static String getStackTraceSamples(int microseconds) {
    return engine.getStackTraceSamples(microseconds);
  }

  /// 停止栈采集
  static void stopStackTraceSamples(){
    engine.stopStackTraceSamples();
  }

  /// 开启低内存获取堆镜像
  static void enableDumpLowMemoryHeapSnapshot(String outFilePath){
    _lowMemoryCallbacks.add((){
      requestHeapSnapshot(outFilePath);
    });
  }

  /// 注册低内存回调
  static int registerLowMemoryCallback(LowMemoryCallback cb){
    if(cb==null){
      return -1;
    }
    _lowMemoryCallbacks.add(cb);
    return _lowMemoryCallbacks.length-1;
  }

  /// 解除低内存回调
  static bool unRegisterLowMemoryCallback(LowMemoryCallback cb){
    if(cb==null){
      return false;
    }
    return _lowMemoryCallbacks.remove(cb);
  }

  /// 解除低内存回调
  static bool unRegisterLowMemoryCallbackByIndex(int index){
    return _lowMemoryCallbacks.remove(index);
  }

  /// VM 会调用该方法
  @pragma("vm:entry-point")
  static void _performLowMemoryCallback(){
    print("Performance performLowMemoryCallback");
    _lowMemoryCallbacks.forEach((f)=>f());
  }

  /// 获取堆快照
  static bool requestHeapSnapshot(String outFilePath){
    File outFile=File(outFilePath);
    if(outFile.existsSync()){
      outFile.createSync(recursive:true);
    }
    return engine.requestHeapSnapshot(outFilePath);
  }

  /// 解析堆快照
  static Future<HeapSnapshot> parseHeapSnapshot(String filePath) async{
    File file = File(filePath);
    if(!await file.exists()){
      return null;
    }
    Uint8List datas = await file.readAsBytes();
    var snapshot = HeapSnapshot();
    await snapshot.loadProgress(datas).last;
    return snapshot;
  }

  static String getHeapUsageJSON() {
    return engine.getHeapInfo();
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
    return engine.getImageMemoryUsage();
  }
}
