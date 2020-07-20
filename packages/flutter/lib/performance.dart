import 'dart:io';
import 'dart:typed_data';
/// The Flutter Monitor framework.
///
/// To use, import `package:flutter/performance.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

import 'dart:ui' as engine;

import 'package:flutter/src/performance/heap_snapshot.dart';


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
  static Future<HeapSnapshot> parseSnapshot(String filePath) async{
    File file = File(filePath);
    if(!await file.exists()){
      return null;
    }
    Uint8List datas = await file.readAsBytes();
    var snapshot = HeapSnapshot();
    await snapshot.loadProgress(datas).last;
    return snapshot;
  }

  static String getHeapInfo() {
    return engine.getHeapInfo();
  }
}
