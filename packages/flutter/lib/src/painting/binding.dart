// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Uint8List;
// BD MOD:
// import 'dart:ui' as ui show instantiateImageCodec, Codec;
import 'dart:ui' as ui show instantiateImageCodec, Codec, getNativeImage, Image, instantiateNativeImageCodec;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ServicesBinding;

import 'image_cache.dart';
import 'shader_warm_up.dart';

/// Binding for the painting library.
///
/// Hooks into the cache eviction logic to clear the image cache.
///
/// Requires the [ServicesBinding] to be mixed in earlier.
mixin PaintingBinding on BindingBase, ServicesBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _imageCache = createImageCache();
    if (shaderWarmUp != null) {
      shaderWarmUp.execute();
    }
  }

  /// The current [PaintingBinding], if one has been created.
  static PaintingBinding get instance => _instance;
  static PaintingBinding _instance;

  /// [ShaderWarmUp] to be executed during [initInstances].
  ///
  /// If the application has scenes that require the compilation of complex
  /// shaders that are not covered by [DefaultShaderWarmUp], it may cause jank
  /// in the middle of an animation or interaction. In that case, set
  /// [shaderWarmUp] to a custom [ShaderWarmUp] before calling [initInstances]
  /// (usually before [runApp] for normal Flutter apps, and before
  /// [enableFlutterDriverExtension] for Flutter driver tests). Paint the scene
  /// in the custom [ShaderWarmUp] so Flutter can pre-compile and cache the
  /// shaders during startup. The warm up is only costly (100ms-200ms,
  /// depending on the shaders to compile) during the first run after the
  /// installation or a data wipe. The warm up does not block the main thread
  /// so there should be no "Application Not Responding" warning.
  ///
  /// Currently the warm-up happens synchronously on the GPU thread which means
  /// the rendering of the first frame on the GPU thread will be postponed until
  /// the warm-up is finished.
  ///
  /// See also:
  ///
  ///  * [ShaderWarmUp], the interface of how this warm up works.
  static ShaderWarmUp shaderWarmUp = const DefaultShaderWarmUp();

  /// The singleton that implements the Flutter framework's image cache.
  ///
  /// The cache is used internally by [ImageProvider] and should generally not
  /// be accessed directly.
  ///
  /// The image cache is created during startup by the [createImageCache]
  /// method.
  ImageCache get imageCache => _imageCache;
  ImageCache _imageCache;

  /// Creates the [ImageCache] singleton (accessible via [imageCache]).
  ///
  /// This method can be overridden to provide a custom image cache.
  @protected
  ImageCache createImageCache() => ImageCache();

  /// Calls through to [dart:ui] with [decodedCacheRatioCap] from [ImageCache].
  ///
  /// The [cacheWidth] and [cacheHeight] parameters, when specified, indicate the
  /// size to decode the image to.
  ///
  /// Both [cacheWidth] and [cacheHeight] must be positive values greater than or
  /// equal to 1 or null. It is valid to specify only one of [cacheWidth] and
  /// [cacheHeight] with the other remaining null, in which case the omitted
  /// dimension will decode to its original size. When both are null or omitted,
  /// the image will be decoded at its native resolution.
  Future<ui.Codec> instantiateImageCodec(Uint8List bytes, {
    int cacheWidth,
    int cacheHeight,
  }) {
    assert(cacheWidth == null || cacheWidth > 0);
    assert(cacheHeight == null || cacheHeight > 0);
    return ui.instantiateImageCodec(
      bytes,
      targetWidth: cacheWidth,
      targetHeight: cacheHeight,
    );
  }

  /**
   * BD ADD:
   */
  Future<ui.Codec> instantiateNativeImageCodec(String url, {int width: 0, int height: 0, double scale: 1.0}) {
    return ui.instantiateNativeImageCodec(url, width: width, height: height, scale: scale);
  }

  /**
   * BD ADD:
   */
  Future<ui.Image> getNativeImage(String url, {int width: 0, int height: 0, double scale: 1.0}) {
    return ui.getNativeImage(url, width: width, height: height, scale: scale);
  }

  @override
  void evict(String asset) {
    super.evict(asset);
    imageCache.clear();
  }

  /// Listenable that notifies when the available fonts on the system have
  /// changed.
  ///
  /// System fonts can change when the system installs or removes new font. To
  /// correctly reflect the change, it is important to relayout text related
  /// widgets when this happens.
  ///
  /// Objects that show text and/or measure text (e.g. via [TextPainter] or
  /// [Paragraph]) should listen to this and redraw/remeasure.
  Listenable get systemFonts => _systemFonts;
  final _SystemFontsNotifier _systemFonts = _SystemFontsNotifier();

  @override
  Future<void> handleSystemMessage(Object systemMessage) async {
    await super.handleSystemMessage(systemMessage);
    final Map<String, dynamic> message = systemMessage;
    final String type = message['type'];
    switch (type) {
      case 'fontsChange':
        _systemFonts.notifyListeners();
        break;
    }
    return;
  }
}

class _SystemFontsNotifier extends Listenable {
  final Set<VoidCallback> _systemFontsCallbacks = <VoidCallback>{};

  void notifyListeners () {
    for (VoidCallback callback in _systemFontsCallbacks) {
      callback();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _systemFontsCallbacks.add(listener);
  }
  @override
  void removeListener(VoidCallback listener) {
    _systemFontsCallbacks.remove(listener);
  }
}

/// The singleton that implements the Flutter framework's image cache.
///
/// The cache is used internally by [ImageProvider] and should generally not be
/// accessed directly.
///
/// The image cache is created during startup by the [PaintingBinding]'s
/// [PaintingBinding.createImageCache] method.
ImageCache get imageCache => PaintingBinding.instance.imageCache;
