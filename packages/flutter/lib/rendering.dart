// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

/// The Flutter rendering tree.
///
/// To use, import `package:flutter/rendering.dart`.
///
/// The [RenderObject] hierarchy is used by the Flutter Widgets library to
/// implement its layout and painting back-end. Generally, while you may use
/// custom [RenderBox] classes for specific effects in your applications, most
/// of the time your only interaction with the [RenderObject] hierarchy will be
/// in debugging layout issues.
///
/// If you are developing your own library or application directly on top of the
/// rendering library, then you will want to have a binding (see [BindingBase]).
/// You can use [RenderingFlutterBinding], or you can create your own binding.
/// If you create your own binding, it needs to import at least
/// [ServicesBinding], [GestureBinding], [SchedulerBinding], [PaintingBinding],
/// and [RendererBinding]. The rendering library does not automatically create a
/// binding, but relies on one being initialized with those features.
library rendering;

export 'package:flutter/foundation.dart' show
  VoidCallback,
  ValueChanged,
  ValueGetter,
  ValueSetter,
  DiagnosticLevel;
export 'package:flutter/semantics.dart';
export 'package:vector_math/vector_math_64.dart' show Matrix4;

export 'src/rendering/animated_size.dart';
export 'src/rendering/binding.dart';
export 'src/rendering/box.dart';
export 'src/rendering/custom_layout.dart';
export 'src/rendering/custom_paint.dart';
export 'src/rendering/debug.dart';
export 'src/rendering/debug_overflow_indicator.dart';
export 'src/rendering/editable.dart';
export 'src/rendering/error.dart';
export 'src/rendering/flex.dart';
export 'src/rendering/flow.dart';
export 'src/rendering/image.dart';
export 'src/rendering/layer.dart';
export 'src/rendering/list_body.dart';
export 'src/rendering/list_wheel_viewport.dart';
export 'src/rendering/mouse_cursor.dart';
export 'src/rendering/mouse_tracking.dart';
export 'src/rendering/object.dart';
export 'src/rendering/paragraph.dart';
export 'src/rendering/performance_overlay.dart';
export 'src/rendering/platform_view.dart';
export 'src/rendering/proxy_box.dart';
export 'src/rendering/proxy_sliver.dart';
export 'src/rendering/rotated_box.dart';
export 'src/rendering/shifted_box.dart';
export 'src/rendering/sliver.dart';
export 'src/rendering/sliver_fill.dart';
export 'src/rendering/sliver_fixed_extent_list.dart';
export 'src/rendering/sliver_grid.dart';
export 'src/rendering/sliver_list.dart';
// BD ADD:
export 'src/rendering/sliver_list_extent.dart';
export 'src/rendering/sliver_multi_box_adaptor.dart';
export 'src/rendering/sliver_padding.dart';
export 'src/rendering/sliver_persistent_header.dart';
export 'src/rendering/stack.dart';
export 'src/rendering/table.dart';
export 'src/rendering/table_border.dart';
export 'src/rendering/texture.dart';
export 'src/rendering/tweens.dart';
export 'src/rendering/view.dart';
export 'src/rendering/viewport.dart';
export 'src/rendering/viewport_offset.dart';
export 'src/rendering/wrap.dart';

