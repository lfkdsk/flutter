import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../../performance.dart';
import '../../widgets.dart';
import 'framework.dart';

typedef _RegisterServiceExtensionCallback = void Function({
  @required String name,
  @required ServiceExtensionCallback callback,
});

class _BytedanceProfileExtension = Object with BytedanceProfileExtension;

mixin BytedanceProfileExtension {
  static bool _debugServiceExtensionsRegistered = false;

  static BytedanceProfileExtension get instance => _instance;
  static final BytedanceProfileExtension _instance =
      _BytedanceProfileExtension();

  void initServiceExtensions(
      _RegisterServiceExtensionCallback registerServiceExtensionCallback) {

    _registerServiceExtensionCallback = registerServiceExtensionCallback;

    assert(!_debugServiceExtensionsRegistered);
    assert(() {
      _debugServiceExtensionsRegistered = true;
      return true;
    }());

    developer.postEvent('flutter.engineLaunchInfo', <String, Object>{
      'result': Performance.getEngineInitApmInfo()
    });

    registerServiceExtension(
      name: 'detectImages',
      callback: (Map<String, String> parameters) async {
        final List<String> detectedImages =
            json.decode(parameters['detected_images']).cast<String>();
        return <String, Object>{
          'result': await _detectImages(detectedImages.toSet()),
        };
      },
    );
    registerServiceExtension(
      name: 'engineLaunchInfo',
      callback: (Map<String, String> parameters) async {
        return <String, Object>{
          'result': Performance.getEngineInitApmInfo()
        };
      }
    );
  }

  _RegisterServiceExtensionCallback _registerServiceExtensionCallback;

  @protected
  void registerServiceExtension({
    @required String name,
    @required ServiceExtensionCallback callback,
  }) {
    _registerServiceExtensionCallback(
      name: 'bd.profile.$name',
      callback: callback,
    );
  }

  Future<Map<String, Object>> _detectImages(Set<String> detectedImages) async {
    final List<Map<String, Object>> imageInfos = <Map<String, Object>>[];
    final List<Future<void>> futureTasks = <Future<void>>[];

    Future<void> traversal(DiagnosticsNode node) async {
      final Element element = node.value as Element;
      final dynamic widget = element.widget;
      if (widget.runtimeType.toString() == 'Image' ||
          widget.runtimeType.toString() == 'AdvancedImage') {
        final double width = widget.width == null
            ? null
            : widget.width * window.devicePixelRatio;
        final double height = widget.height == null
            ? null
            : widget.height * window.devicePixelRatio;
        final dynamic imageProvider = widget.image;
        final DiagnosticPropertiesBuilder builder =
            DiagnosticPropertiesBuilder();
        (element as StatefulElement).state.debugFillProperties(builder);
        ImageInfo imageInfo;
        if (widget.runtimeType.toString() == 'AdvancedImage') {
          imageInfo = builder.properties
              .elementAt(builder.properties.length - 1)
              .value as ImageInfo;
        } else {
          imageInfo = builder.properties
              .elementAt(builder.properties.length - 4)
              .value as ImageInfo;
        }
        if (imageInfo == null) {
          return;
        }
        String imageKey = 'unknown';
        String type = 'unknown';
        if (imageProvider.runtimeType.toString() == 'NetworkImage' ||
            imageProvider.runtimeType.toString() ==
                'AdvancedNetworkImageProvider') {
          imageKey = imageProvider.url;
          type = 'network';
        } else if (imageProvider.runtimeType.toString() == 'FileImage' ||
            imageProvider.runtimeType.toString() == 'ByteFileImage') {
          imageKey = imageProvider.file.path;
          type = 'file';
        } else if (imageProvider.runtimeType.toString() == 'AssetImage' ||
            imageProvider.runtimeType.toString() == 'ExactAssetImage') {
          imageKey = imageProvider.keyName;
          type = 'asset';
        }
        if (detectedImages.contains(imageKey)) {
          return;
        }
        if (imageInfos
            .map((Map<String, Object> info) => info['key'])
            .contains(imageKey)) {
          return;
        }
        final Map<String, Object> info = <String, Object>{
          'widget_width': width.toString(),
          'widget_height': height.toString(),
          'image_width': imageInfo.image.width.toString(),
          'image_height': imageInfo.image.height.toString(),
          'image_scale': imageInfo.scale.toString(),
          'key': imageKey,
          'type': type,
        };
        imageInfos.add(info);
        final Completer<void> completer = Completer<void>();
        futureTasks.add(completer.future);
        final ByteData byteData =
            await imageInfo.image.toByteData(format: ImageByteFormat.png);
        final Uint8List data = byteData.buffer.asUint8List();
        info['data'] = data;
        if (type == 'file') {
          final int size = await File(imageKey).length();
          info['size'] = size;
        }
        completer.complete();
      } else if (node.getChildren().isNotEmpty) {
        node.getChildren().forEach((DiagnosticsNode element) {
          traversal(element);
        });
      }
    }

    traversal(WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode());
    await Future.wait<void>(<Future<void>>[...futureTasks]);
    return imageInfos.asMap().map((int index, Map<String, Object> infos) =>
        MapEntry<String, String>(index.toString(), json.encode(infos)));
  }
}

class _BytedanceDebugExtension = _BytedanceProfileExtension
    with BytedanceDebugExtension;

mixin BytedanceDebugExtension on BytedanceProfileExtension {
  static BytedanceDebugExtension get instance => _instance;
  static final BytedanceDebugExtension _instance = _BytedanceDebugExtension();

  @override
  void initServiceExtensions(
      _RegisterServiceExtensionCallback registerServiceExtensionCallback) {}
}