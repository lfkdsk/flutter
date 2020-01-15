import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'smooth_simulation.dart';

/**
 * 使用了移植Android滑动阻尼算法的[SmoothScrollSimulation],实现Android原生的列表滑动体验，
 */

class SmoothScrollPhysics extends ScrollPhysics implements IScrollStartConsumedListener {
  static bool _isScrollStartConsumed = false;

  final ScrollPhysics customPhysics;

  /// 创建一个ScrollPhysics, 可以通过传入[customPhysics]使用用户自定义的滑动行为，但[createBallisticSimulation]
  /// 方法不会使用customPhysics的Simulation，而是被[SmoothScrollSimulation]接管
  SmoothScrollPhysics({this.customPhysics, ScrollPhysics parent}) : super(parent: parent);

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SmoothScrollPhysics(customPhysics: customPhysics, parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => customPhysics?.shouldAcceptUserOffset(position) ?? true;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (customPhysics != null)
      return customPhysics.applyPhysicsToUserOffset(position, offset);
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (customPhysics != null)
      return customPhysics.applyBoundaryConditions(position, value);
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (position.outOfRange) {
        if (customPhysics != null) {
          return customPhysics.createBallisticSimulation(position, velocity);
        } else {
          return super.createBallisticSimulation(position, velocity);
        }
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
      if (customPhysics != null) {
        return customPhysics.createBallisticSimulation(position, velocity);
      } else {
        return super.createBallisticSimulation(position, velocity);
      }
    }
  }

  @override
  void onScrollStartConsumed(bool consumed) {
    _isScrollStartConsumed = consumed;
  }
}
