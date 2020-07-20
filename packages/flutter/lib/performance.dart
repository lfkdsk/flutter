import 'dart:io';
import 'dart:typed_data';
/// The Flutter Monitor framework.
///
/// To use, import `package:flutter/performance.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

import 'dart:ui' as engine;

import 'package:flutter/src/snapshot_graph.dart';

class Performance {

  // 开始栈采集
  static void startStackTraceSamples(){
    engine.startStackTraceSamples();
  }

  // 拿到最近 microseconds（微秒） 时间段的栈采集信息{func_name:exec_count}
  static String getStackTraceSamples(int microseconds) {
    return engine.getStackTraceSamples(microseconds);
  }

  // 停止栈采集
  static void stopStackTraceSamples(){
    engine.stopStackTraceSamples();
  }

  // 获取堆快照
  static bool requestHeapSnapshot(String outFilePath){
    File outFile=File(outFilePath);
    if(outFile.existsSync()){
      outFile.createSync(recursive:true);
    }
    return engine.requestHeapSnapshot(outFilePath);
  }

  // 解析堆快照
  static Future<HeapSnapshotGraph> parseSnapshot(String filePath) async{
    return await HeapSnapshotGraph.parseSnapshot(filePath);
  }

  static String getHeapInfo() {
    return engine.getHeapInfo();
  }
}
