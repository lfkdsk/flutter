
// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/**
 * 移植Android滑动阻尼算法的Simulation, 滑动效果和Android的RecylerView或Listview一样
 */

const double INFLEXION = 0.35;
const double START_TENSION = 0.5;
const double END_TENSION = 1.0;
const double P1 = START_TENSION * INFLEXION;
const double P2 = 1.0 - END_TENSION * (1.0 - INFLEXION);
const double GRAVITY_EARTH = 9.80665;

abstract class IScrollStartConsumedListener {
  void onScrollStartConsumed(bool consumed);
}

class SmoothScrollSimulation extends Simulation {
  /// Creates a scroll physics simulation that matches Android scrolling.
  SmoothScrollSimulation(IScrollStartConsumedListener scrollListener, {
    @required this.position,
    @required this.velocity,
    @required bool needCalculateInitSetting,
    this.friction = 0.015,
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    checkInit();
    if (needCalculateInitSetting || _duration == null || _startTime == 0 || _distance == null) {
      _startTime = DateTime.now().microsecondsSinceEpoch;
      _startPosition = position;
      double totalDistance = 0.0;
      velocity *= _density;
      _duration = _calculateFlingDuration(velocity);
      totalDistance = _calculateFlingDistance(velocity);
      _distance = totalDistance * (velocity).sign / _density;
      scrollListener.onScrollStartConsumed(true);
    }
  }

  static int nbSamples = 100;
  static List<double> splinePosition = List(nbSamples + 1);
  static List<double> splineTime = List(nbSamples + 1);

  /// The position of the particle at the beginning of the simulation.
  final double position;

  /// The velocity at which the particle is traveling at the beginning of the
  /// simulation.
  double velocity;

  /// The amount of friction the particle experiences as it travels.
  ///
  /// The more friction the particle experiences, the sooner it stops.
  final double friction;

  static double _duration;
  static double _distance;

  final double _density = WidgetsBinding.instance.window.devicePixelRatio;
  final double _physicalCoefficient = GRAVITY_EARTH * 39.37 * WidgetsBinding.instance.window.devicePixelRatio * 160 * 0.84;
  static int _startTime = 0;
  static double _startPosition = 0;
  static bool hasInit = false;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  static void checkInit() {
    if (hasInit) return;
    double xMin = 0.0;
    double yMin = 0.0;
    for (int i = 0; i < nbSamples; i++) {
      final double alpha = i / nbSamples;

      double xMax = 1.0;
      double x, tx, coefficient;
      while (true) {
        x = xMin + (xMax - xMin) / 2.0;
        coefficient = 3.0 * x * (1.0 - x);
        tx = coefficient * ((1.0 - x) * P1 + x * P2) + x * x * x;
        if ((tx - alpha).abs() < 1E-5) break;
        if (tx > alpha)
          xMax = x;
        else
          xMin = x;
      }
      splinePosition[i] = coefficient * ((1.0 - x) * START_TENSION + x) + x * x * x;

      double yMax = 1.0;
      double y, dy;
      while (true) {
        y = yMin + (yMax - yMin) / 2.0;
        coefficient = 3.0 * y * (1.0 - y);
        dy = coefficient * ((1.0 - y) * START_TENSION + y) + y * y * y;
        if ((dy - alpha).abs() < 1E-5) break;
        if (dy > alpha)
          yMax = y;
        else
          yMin = y;
      }
      splineTime[i] = coefficient * ((1.0 - y) * P1 + y * P2) + y * y * y;
    }
    splinePosition[nbSamples] = splineTime[nbSamples] = 1.0;
    hasInit = true;
  }

  double _calculateDeceleration(double velocity) {
    return math.log(INFLEXION * velocity.abs() / (friction * _physicalCoefficient));
  }

  double _calculateFlingDistance(double velocity) {
    final double l = _calculateDeceleration(velocity);
    final double decelerationMinusOne = _kDecelerationRate - 1.0;
    return friction * _physicalCoefficient * math.exp(_kDecelerationRate / decelerationMinusOne * l);
  }

  /* Returns the duration, expressed in seconds */
  double _calculateFlingDuration(double velocity) {
    final double l = _calculateDeceleration(velocity);
    final double decelerationMinusOne = _kDecelerationRate - 1.0;
    return math.exp(l / decelerationMinusOne);
  }

  @override
  double x(double time) {
    double timeOffset = curTime();
    final double t = timeOffset / _duration;
    final int index = (nbSamples * t).toInt();
    double distanceCoefficient = 1.0;
    double velocityCoefficient = 0;
    if (index >= 0 && index < nbSamples) {
      final double tInf = (index / nbSamples).toDouble();
      final double tSup = ((index + 1) / nbSamples).toDouble();
      final double dInf = splinePosition[index];
      final double dSup = splinePosition[index + 1];
      velocityCoefficient = (dSup - dInf) / (tSup - tInf);
      distanceCoefficient = dInf + (t - tInf) * velocityCoefficient;
    }
    double x = _startPosition + distanceCoefficient * _distance;
    return x;
  }

  @override
  double dx(double time) {
    double timeOffset = curTime();
    final double t = timeOffset / _duration;
    final int index = (nbSamples * t).toInt();
    double velocityCoefficient = 0;
    if (index >= 0 && index < nbSamples) {
      final double tInf = (index / nbSamples).toDouble();
      final double tSup = ((index + 1) / nbSamples).toDouble();
      final double dInf = splinePosition[index];
      final double dSup = splinePosition[index + 1];
      velocityCoefficient = (dSup - dInf) / (tSup - tInf);
    }
    double dx = velocityCoefficient * _distance / _duration;
    return dx;
  }

  @override
  bool isDone(double time) {
    return curTime() >= _duration;
  }

  double curTime() {
    return (DateTime.now().microsecondsSinceEpoch - _startTime) / 1000000.0;
  }
}
