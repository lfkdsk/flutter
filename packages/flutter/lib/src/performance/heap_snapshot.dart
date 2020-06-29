// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/src/performance/object_graph.dart';

class HeapSnapshot {
  SnapshotGraph graph;
  DateTime timestamp;
  int get size => graph.shallowSize + graph.externalSize;
  List<SnapshotClass> classes;
  SnapshotObject get root => graph.root;

  Stream<String> loadProgress(Uint8List encoded) {
    final progress = new StreamController<String>.broadcast();
    progress.add('Loading...');
    graph = new SnapshotGraph(encoded);
    (() async {
      timestamp = new DateTime.now();
      final stream = graph.process();
      stream.listen((status) {
        progress.add(status);
      });
      await stream.last;
      classes = graph.classes.toList();
      progress.close();
    }());
    return progress.stream;
  }
}
