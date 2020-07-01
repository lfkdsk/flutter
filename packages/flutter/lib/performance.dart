/// The Flutter Monitor framework.
///
/// To use, import `package:flutter/performance.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

import 'dart:ui' as engine;

class Performance {

  // 开始栈采集
  static void startStackTraceSamples(){
    engine.startStackTraceSamples();
  }

  // 拿到最近 microseconds 时间段的栈采集信息
  static String getStackTraceSamples(int microseconds) {
    engine.getStackTraceSamples(microseconds);
  }

  // 停止栈采集
  static void stopStackTraceSamples(){
    engine.stopStackTraceSamples();
  }

  // 获取堆快照
  static String getHeapSnapshot(){

  }


}
