/**
 * BD ADD:
 */

// @dart = 2.8

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Utils For record fps
class FpsUtils {
  FpsUtils._internal() {
    _recordedData = <FpsData>[];
    _timers = <String, Timer>{};
  }

  /// for framework to record fps, do not use in business
  static const String _frameWorkPrefix = 'Framework_';
  static const int _recordListLength = 500;

  /// getInstance
  static FpsUtils get instance => _getInstance();
  static FpsUtils _instance;

  List<FpsData> _recordedData;
  Map<String, Timer> _timers;

  /// For the key of auto record fps,
  /// The business logic in Plugin will lead to widgetCreateLocation of
  /// loacal project error
  /// So,we need a list of businessPlugin to help judge.
  List<String> businessPlugins;

  /// For the key of auto record fps,
  /// We will simplify key based on '/',
  /// This variable can control the number of ‘/’
  int hierarchyCountOfKey = 1;

  static FpsUtils _getInstance() {
    _instance ??= FpsUtils._internal();
    return _instance;
  }

  bool _isEnable = false;

  /// open the auto record fps in framework
  set enableAutoRecord(bool value) {
    _isEnable = value;
  }

  /// is auto record enable
  /// if recordData is full, indicates that there is no consumer,
  /// then no longer continue to automatically record data
  bool get enableAutoRecord {
    return _isEnable && _recordedData.length < _recordListLength;
  }

  /// Start record the fps, if still not call getFps, data will be clear
  ///
  /// Attention:startRecord and getFps must be paired
  void startRecord(String key,
      {Duration timeOut, bool isFromFramework = false}) {
    if (isFromFramework) {
      key = _frameWorkPrefix + key;
    }
    ui.performance.startRecordFps(key);
    if (timeOut != null) {
      _timers[key] = Timer(timeOut, () {
        getFps(key, true, isFromFramework: isFromFramework);
      });
    }
  }

  /// Get the fps for this key
  /// stopRecord: true: clear data of this key after return fps
  ///             false: continue record data after return
  ///
  /// Attention: startRecord and getFps must be paired
  FpsData getFps(String key, bool stopRecord,
      {bool recordInFramework = false, bool isFromFramework = false}) {
    if (isFromFramework) {
      key = _frameWorkPrefix + key;
    }
    _timers.remove(key)?.cancel();
    final List<dynamic> fpsDataList = ui.performance.obtainFps(key, stopRecord);
    final FpsData fpsData = FpsData.fromList(key, fpsDataList);
    if (recordInFramework) {
      _recordedData.add(fpsData);
      if (!kReleaseMode) {
        debugPrint(fpsData.toString());
      }
    }
    return fpsData;
  }

  /// Auto recorded data for Scroll, Animation, Route
  List<FpsData> getFpsDataRecordInFramework(bool erase) {
    final List<FpsData> temp = List<FpsData>.from(_recordedData);
    if (erase) {
      _recordedData.clear();
    }
    return temp;
  }
}

/// Structure of Fps data
class FpsData {
  /// directly construct FpsData
  FpsData.factory(this.key, this.fps, this.uiAvgTime, this.gpuAvgTime);

  /// construct FpsData
  FpsData.fromList(this.key, List<dynamic> fpsData)
      : fps = (fpsData[0] * 100.0).round() / 100,
        uiAvgTime = (fpsData[1] * 100.0).round() / 100,
        gpuAvgTime = (fpsData[2] * 100.0).round() / 100;

  /// Copy the data
  FpsData.copyWith(FpsData data)
      : _count = data._count,
        key = data.key,
        fps = data.fps,
        uiAvgTime = data.fps,
        gpuAvgTime = data.gpuAvgTime;

  /// count for accumulation the FpsData
  int _count = 1;

  /// Key of Fps
  String key;

  /// Fps value
  double fps;

  /// Average time spent on UI thread
  double uiAvgTime;

  /// Average time spent on GPU thread
  double gpuAvgTime;

  /// fps data is valid
  bool isValid() {
    return fps > 0;
  }

  /// accumulation the FpsData and get the average value
  static List<FpsData> averageFpsDataList(List<FpsData> dataList) {
    if (dataList?.isEmpty ?? true) {
      return dataList;
    }
    final Map<String, FpsData> totalData = <String, FpsData>{};
    for (FpsData data in dataList) {
      if (!data.isValid()) {
        continue;
      }
      final FpsData dataInMap = totalData[data.key];
      if (dataInMap == null) {
        totalData[data.key] = FpsData.copyWith(data);
      } else {
        dataInMap._accumulationData(data);
      }
    }
    final List<FpsData> result = <FpsData>[];
    for (FpsData data in totalData.values) {
      data._averageData();
      result.add(data);
    }
    return result;
  }

  void _accumulationData(FpsData newData) {
    _count += newData._count;
    fps += newData.fps;
    uiAvgTime += newData.uiAvgTime;
    gpuAvgTime += newData.gpuAvgTime;
  }

  void _averageData() {
    if (_count == 1) {
      return;
    }
    fps /= _count;
    uiAvgTime /= _count;
    gpuAvgTime /= _count;
    _count = 1;
  }

  @override
  String toString() {
    return 'FpsData:{key:$key,fps:$fps,uiAvgTime:$uiAvgTime,gpuAvgTime:$gpuAvgTime}';
  }
}
