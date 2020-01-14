import 'dart:math' as math;
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
  SmoothScrollPhysics({this.customPhysics, ScrollPhysics parent}): super(parent: parent);

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

    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange)
      return offset;

    final double overScrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overScrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overScrollPast = math.max(overScrollPastStart, overScrollPastEnd);
    final bool easing = (overScrollPastStart > 0.0 && offset < 0.0)
        || (overScrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor((overScrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overScrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overScrollPast, offset.abs(), friction);
  }

  static double _applyFriction(double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  double frictionFactor(double overScrollFraction) => 0.52 * math.pow(1 - overScrollFraction, 2);

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (customPhysics != null)
      return customPhysics.applyBoundaryConditions(position, value);

    if (value < position.pixels && position.pixels <= position.minScrollExtent) // underscroll
      return value - position.pixels;
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) // overscroll
      return value - position.pixels;
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) // hit top edge
      return value - position.minScrollExtent;
    if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) // hit bottom edge
      return value - position.maxScrollExtent;
    return 0.0;
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
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
  }

  @override
  void onScrollStartConsumed(bool consumed) {
    _isScrollStartConsumed = consumed;
  }
}
