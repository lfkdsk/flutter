import 'dart:ui' as ui;

/// Utils For record fps
class FpsUtils {
  FpsUtils._internal() {
    _recordedData = <FpsData>[];
  }

  ///getInstance
  static FpsUtils get instance => _getInstance();
  static FpsUtils _instance;

  List<FpsData> _recordedData;

  static FpsUtils _getInstance() {
    _instance ??= FpsUtils._internal();
    return _instance;
  }

  void startRecord(String key) {
    ui.window.startRecordFps(key);
  }

  FpsData getFps(String key, bool stopRecord,
      {bool recordInFramework = false}) {
    final List<dynamic> fpsDataList = ui.window.obtainFps(key, stopRecord);
    final FpsData fpsData = FpsData.fromList(key, fpsDataList);
    if (recordInFramework) {
      _recordedData.add(fpsData);
      print(fpsData.toString());
    }
    return fpsData;
  }

  List<FpsData> getFpsDataRecordInFramework(bool erase) {
    final List<FpsData> temp = List<FpsData>.from(_recordedData);
    if (erase) {
      _recordedData.clear();
    }
    return temp;
  }
}

class FpsData {
  String key;
  double fps;
  double uiAvgTime;
  double gpuAvgTime;

  FpsData.fromList(this.key, List<dynamic> fpsData) {
    final double fps = fpsData[0];
    this.fps = (fps * 100.0).round() / 100;
    final double uiAvgTime = fpsData[1];
    this.uiAvgTime = (uiAvgTime * 100.0).round() / 100;
    final double gpuAvgTime = fpsData[2];
    this.gpuAvgTime = (gpuAvgTime * 100.0).round() / 100;
  }

  @override
  String toString() {
    return 'FpsData:{key:$key,fps:$fps,uiAvgTime:$uiAvgTime,gpuAvgTime:$gpuAvgTime}';
  }
}
