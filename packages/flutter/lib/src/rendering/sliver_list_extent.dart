// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math';

import 'package:flutter/boost.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

/// A sliver that places multiple box children in a linear array along the main
/// axis.
///
/// Each child is forced to have the [SliverConstraints.crossAxisExtent] in the
/// cross axis but determines its own main axis extent.
///
/// [RenderSliverList] determines its scroll offset by "dead reckoning" because
/// children outside the visible part of the sliver are not materialized, which
/// means [RenderSliverList] cannot learn their main axis extent. Instead, newly
/// materialized children are placed adjacent to existing children. If this dead
/// reckoning results in a logical inconsistency (e.g., attempting to place the
/// zeroth child at a scroll offset other than zero), the [RenderSliverList]
/// generates a [SliverGeometry.scrollOffsetCorrection] to restore consistency.
///
/// If the children have a fixed extent in the main axis, consider using
/// [RenderSliverFixedExtentList] rather than [RenderSliverList] because
/// [RenderSliverFixedExtentList] does not need to perform layout on its
/// children to obtain their extent in the main axis and is therefore more
/// efficient.
///
/// See also:
///
///  * [RenderSliverFixedExtentList], which is more efficient for children with
///    the same extent in the main axis.
///  * [RenderSliverGrid], which places its children in arbitrary positions.
class RenderSliverListExtent extends RenderSliverList {
  /// Creates a sliver that places multiple box children in a linear array along
  /// the main axis.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverListExtent({
    @required RenderSliverBoxChildManager childManager,
    double scrollingExtent,
    double scrollEndExtent,
  })  : scrollingExtent = scrollingExtent ?? 0.0,
        scrollEndExtent = scrollEndExtent ?? 0.0,
        super(childManager: childManager);

  /// 滚动中预加载下一帧，不宜过大，否则可能在滚动中预加载多帧的数据
  final double scrollingExtent;

  /// 滚动结束后页面静止时间较长，可以比 scrollingExtent 大
  final double scrollEndExtent;

  /// 是否可以开始预加载下一帧
  bool _needScrollEndPreload = false;

  /// 触发重新绘制
  ///
  /// 如果是正数，表示可利用的空闲时间
  /// 1.如果小于 16 ms，表示是滚动过程中
  /// 2.如果大于 100 ms，表示是滚动结束
  ///
  /// 如果是负数，表示已经超过frame_end_time，下一帧已经开始，此时不应再做预布局。两种情况会出现这个问题：
  /// 1.UI线程耗时太长，时间已经超过当前帧的 frame_end_time
  /// 2.垃圾回收耗时太长，时间已经超过当前帧的 frame_end_time
  @override
  void layoutNextFrame(Duration duration) {
    if (duration.inMicroseconds < 3000) {
      return;
    }
    if (duration.inMicroseconds > 100000) {
      _needScrollEndPreload = true;
      Boost.finishRightNow(false, notifyIdle: true);
    }
    super.layoutNextFrame(duration);
  }

  @override
  void performLayout() {
    // 本次是否是滚动中预加载
    final bool canScrollingPreload = scrollingExtent > 0.0 &&
        Boost.localIsIdleCallbacksHandling &&
        !_needScrollEndPreload;
    // 本次是否是滚动结束预加载
    final bool canScrollEndPreload =
        _needScrollEndPreload && scrollEndExtent > 0.0;
    _needScrollEndPreload = false;
    final bool isPreload = canScrollingPreload || canScrollEndPreload;
    assert(canScrollingPreload != true || canScrollEndPreload != true);

    // 确定滚动方向
    final bool isScrollDown =
        constraints.userScrollDirection == ScrollDirection.reverse;
    final bool isScrollUp =
        constraints.userScrollDirection == ScrollDirection.forward;

    // 确定滚动过程中空闲时回调
    Boost.localNotifyIdleCallbackScrolling ??=
        scrollingExtent > 0.0 && !isPreload
            ? layoutNextFrame
            : null;
    Boost.localNotifyIdleCallbackScrollEnd ??=
        scrollEndExtent > 0.0 && !isPreload
            ? layoutNextFrame
            : null;

    if (!isPreload) {
      childManager.didStartLayout();
      childManager.setDidUnderflow(false);
    }

    final double oldScrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    // idlePreBuild&&scrollUp的时候需要向上偏移
    // 预加载Item的时候需要向上编译
    // 取最大值作为scrollOffset的向上偏移量
    final double maxDecrease = max(
        (canScrollingPreload && isScrollUp) ? scrollingExtent : 0.0,
        canScrollEndPreload ? scrollEndExtent : 0.0);
    // 这里计算有问题
    final double scrollOffset = max(0.0, oldScrollOffset - maxDecrease);
    // 向上偏移garbageOffset防止preBuild或者预加载的item被回收
    final double garbageScrollOffset =
        max(0.0, oldScrollOffset - max(scrollEndExtent, scrollingExtent));
    assert(scrollOffset >= 0.0);

    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);

    // idlePreBuild&&scrollDown的时候需要向下偏移
    // 预加载Item的时候需要向下编译
    // 取最大值作为targetEndScrollOffset的向下偏移量
    final double maxIncrease = max(
        (canScrollingPreload && isScrollDown) ? scrollingExtent : 0.0,
        canScrollEndPreload ? scrollEndExtent : 0.0);
    final double targetEndScrollOffset =
        oldScrollOffset + remainingExtent + maxIncrease;

    // 向上偏移garbageEndOffset防止preBuild或者预加载的item被回收
    final double garbageTargetEndScrollOffset = oldScrollOffset +
        remainingExtent +
        max(scrollingExtent, scrollEndExtent);
    final BoxConstraints childConstraints = constraints.asBoxConstraints();
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the list if necessary, then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox leadingChildWithLayout, trailingChildWithLayout;

    // Find the last child that is at or before the scrollOffset.
    RenderBox earliestUsefulChild = firstChild;
    for (double earliestScrollOffset = childScrollOffset(earliestUsefulChild);
        earliestScrollOffset > scrollOffset;
        earliestScrollOffset = childScrollOffset(earliestUsefulChild)) {
      // We have to add children before the earliestUsefulChild.
      earliestUsefulChild =
          insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);

      if (earliestUsefulChild == null) {
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild.parentData;
        childParentData.layoutOffset = 0.0;

        if (scrollOffset == 0.0) {
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // We ran out of children before reaching the scroll offset.
          // We must inform our parent that this sliver cannot fulfill
          // its contract and that we need a scroll offset correction.
          geometry = SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }

      final double firstChildScrollOffset =
          earliestScrollOffset - paintExtentOf(firstChild);
      // firstChildScrollOffset may contain double precision error
      if (firstChildScrollOffset < -precisionErrorTolerance) {
        // The first child doesn't fit within the viewport (underflow) and
        // there may be additional children above it. Find the real first child
        // and then correct the scroll position so that there's room for all and
        // so that the trailing edge of the original firstChild appears where it
        // was before the scroll offset correction.
        // TODO(hansmuller): do this work incrementally, instead of all at once,
        // i.e. find a way to avoid visiting ALL of the children whose offset
        // is < 0 before returning for the scroll correction.
        double correction = 0.0;
        while (earliestUsefulChild != null) {
          assert(firstChild == earliestUsefulChild);
          correction += paintExtentOf(firstChild);
          earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints,
              parentUsesSize: true);
        }
        geometry = SliverGeometry(
          scrollOffsetCorrection: correction - earliestScrollOffset,
        );
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild.parentData;
        childParentData.layoutOffset = 0.0;
        return;
      }

      final SliverMultiBoxAdaptorParentData childParentData =
          earliestUsefulChild.parentData;
      childParentData.layoutOffset = firstChildScrollOffset;
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild) <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;

    // 如果是利用空闲时间预 build，将第一个 Child 直接指向 lastChild
    if (canScrollingPreload && isScrollDown) {
      earliestUsefulChild = lastChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    RenderBox child = earliestUsefulChild;
    int index = indexOf(child);
    double endScrollOffset = childScrollOffset(child) + paintExtentOf(child);
    bool advance() {
      // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout)
        inLayoutRange = false;
      child = childAfter(child);
      if (child == null)
        inLayoutRange = false;
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(
            childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          if (!canScrollingPreload) {
            child.layout(childConstraints, parentUsesSize: true);
          }
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = endScrollOffset;
      assert(childParentData.index == index);
      endScrollOffset = childScrollOffset(child) + paintExtentOf(child);
      return true;
    }

    // Find the first child that ends after the scroll offset.
    while (endScrollOffset < scrollOffset) {
      if (endScrollOffset <= garbageScrollOffset) {
        leadingGarbage += 1;
      }
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent =
            childScrollOffset(lastChild) + paintExtentOf(lastChild);
        geometry = SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        return;
      }
    }

    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }


    double tempEndScrollOffset = endScrollOffset;
    while (tempEndScrollOffset <= garbageTargetEndScrollOffset) {
      if (child == null) {
        break;
      }
      child = childAfter(child);
      if (child != null && child.needsLayout) {
        child.layout(childConstraints, parentUsesSize: true);
      }
      if (child?.hasSize ?? false) {
        // 校正 child 位移，避免出现覆盖问题
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData;
        childParentData.layoutOffset = tempEndScrollOffset;
        tempEndScrollOffset = childScrollOffset(child) + paintExtentOf(child);
      }
    }
    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.

    collectGarbage(leadingGarbage, trailingGarbage);
    // 如果是预加载，后面的逻辑就不用走了
    if (isPreload) {
      return;
    }
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild),
        lastIndex: indexOf(lastChild),
        leadingScrollOffset: childScrollOffset(firstChild),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          endScrollOffset - childScrollOffset(firstChild));
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild),
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint ||
          constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}
