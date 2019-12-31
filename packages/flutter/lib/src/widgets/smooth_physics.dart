
// @dart = 2.8

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'smooth_simulation.dart';

/**
 * 使用了移植Android滑动阻尼算法的[SmoothScrollSimulation],实现Android原生的列表滑动体验，
 */

class SmoothScrollPhysics extends ScrollPhysics implements IScrollStartConsumedListener {
  static bool _isScrollStartConsumed = false;

  SmoothScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (position.outOfRange) {
        return super.createBallisticSimulation(position, velocity);
      }
      if (velocity.abs() < tolerance.velocity) return null;
      if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) return null;
      if (velocity < 0.0 && position.pixels <= position.minScrollExtent) return null;
      return SmoothScrollSimulation(
        this,
        position: position.pixels,
        velocity: velocity,
        needCalculateInitSetting: !_isScrollStartConsumed,
        tolerance: tolerance,
      );
    } else {
      return super.createBallisticSimulation(position, velocity);
    }
  }

  @override
  void onScrollStartConsumed(bool consumed) {
    _isScrollStartConsumed = consumed;
  }
}
