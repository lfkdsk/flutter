// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'android/android_device_discovery.dart';
import 'android/android_workflow.dart';
import 'application_package.dart';
import 'artifacts.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'features.dart';
import 'fuchsia/fuchsia_device.dart';
import 'fuchsia/fuchsia_sdk.dart';
import 'fuchsia/fuchsia_workflow.dart';
import 'globals.dart' as globals;
import 'ios/devices.dart';
import 'ios/simulators.dart';
import 'linux/linux_device.dart';
import 'macos/macos_device.dart';
import 'project.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/windows_device.dart';

DeviceManager get deviceManager => context.get<DeviceManager>();

/// A description of the kind of workflow the device supports.
class Category {
  const Category._(this.value);

  static const Category web = Category._('web');
  static const Category desktop = Category._('desktop');
  static const Category mobile = Category._('mobile');

  final String value;

  @override
  String toString() => value;
}

/// The platform sub-folder that a device type supports.
class PlatformType {
  const PlatformType._(this.value);

  static const PlatformType web = PlatformType._('web');
  static const PlatformType android = PlatformType._('android');
  static const PlatformType ios = PlatformType._('ios');
  static const PlatformType linux = PlatformType._('linux');
  static const PlatformType macos = PlatformType._('macos');
  static const PlatformType windows = PlatformType._('windows');
  static const PlatformType fuchsia = PlatformType._('fuchsia');

  final String value;

  @override
  String toString() => value;
}

/// A class to get all available devices.
class DeviceManager {

  /// Constructing DeviceManagers is cheap; they only do expensive work if some
  /// of their methods are called.
  List<DeviceDiscovery> get deviceDiscoverers => _deviceDiscoverers;
  final List<DeviceDiscovery> _deviceDiscoverers = List<DeviceDiscovery>.unmodifiable(<DeviceDiscovery>[
    AndroidDevices(
      logger: globals.logger,
      androidSdk: globals.androidSdk,
      androidWorkflow: androidWorkflow,
      processManager: globals.processManager,
    ),
    IOSDevices(
      platform: globals.platform,
      xcdevice: globals.xcdevice,
      iosWorkflow: globals.iosWorkflow,
    ),
    IOSSimulators(iosSimulatorUtils: globals.iosSimulatorUtils),
    FuchsiaDevices(
      fuchsiaSdk: fuchsiaSdk,
      logger: globals.logger,
      fuchsiaWorkflow: fuchsiaWorkflow,
      platform: globals.platform,
    ),
    FlutterTesterDevices(),
    MacOSDevices(),
    LinuxDevices(
      platform: globals.platform,
      featureFlags: featureFlags,
    ),
    WindowsDevices(),
    WebDevices(
      featureFlags: featureFlags,
      fileSystem: globals.fs,
      platform: globals.platform,
      processManager: globals.processManager,
    ),
  ]);

  String _specifiedDeviceId;

  /// A user-specified device ID.
  String get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all') {
      return null;
    }
    return _specifiedDeviceId;
  }

  set specifiedDeviceId(String id) {
    _specifiedDeviceId = id;
  }

  /// True when the user has specified a single specific device.
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  /// True when the user has specified all devices by setting
  /// specifiedDeviceId = 'all'.
  bool get hasSpecifiedAllDevices => _specifiedDeviceId == 'all';

  Future<List<Device>> getDevicesById(String deviceId) async {
    final List<Device> devices = await getAllConnectedDevices();
    deviceId = deviceId.toLowerCase();
    bool exactlyMatchesDeviceId(Device device) =>
        device.id.toLowerCase() == deviceId ||
        device.name.toLowerCase() == deviceId;
    bool startsWithDeviceId(Device device) =>
        device.id.toLowerCase().startsWith(deviceId) ||
        device.name.toLowerCase().startsWith(deviceId);

    final Device exactMatch = devices.firstWhere(
        exactlyMatchesDeviceId, orElse: () => null);
    if (exactMatch != null) {
      return <Device>[exactMatch];
    }

    // Match on a id or name starting with [deviceId].
    return devices.where(startsWithDeviceId).toList();
  }

  /// Returns the list of connected devices, filtered by any user-specified device id.
  Future<List<Device>> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  Iterable<DeviceDiscovery> get _platformDiscoverers {
    return deviceDiscoverers.where((DeviceDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Returns the list of all connected devices.
  Future<List<Device>> getAllConnectedDevices() async {
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.devices,
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Returns the list of all connected devices. Discards existing cache of devices.
  Future<List<Device>> refreshAllConnectedDevices({ Duration timeout }) async {
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.discoverDevices(timeout: timeout),
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Whether we're capable of listing any devices given the current environment configuration.
  bool get canListAnything {
    return _platformDiscoverers.any((DeviceDiscovery discoverer) => discoverer.canListAnything);
  }

  /// Get diagnostics about issues with any connected devices.
  Future<List<String>> getDeviceDiagnostics() async {
    return <String>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        ...await discoverer.getDiagnostics(),
    ];
  }

  /// Find and return a list of devices based on the current project and environment.
  ///
  /// Returns a list of devices specified by the user.
  ///
  /// * If the user specified '-d all', then return all connected devices which
  /// support the current project, except for fuchsia and web.
  ///
  /// * If the user specified a device id, then do nothing as the list is already
  /// filtered by [getDevices].
  ///
  /// * If the user did not specify a device id and there is more than one
  /// device connected, then filter out unsupported devices and prioritize
  /// ephemeral devices.
  Future<List<Device>> findTargetDevices(FlutterProject flutterProject) async {
    List<Device> devices = await getDevices();

    // Always remove web and fuchsia devices from `--all`. This setting
    // currently requires devices to share a frontend_server and resident
    // runnner instance. Both web and fuchsia require differently configured
    // compilers, and web requires an entirely different resident runner.
    if (hasSpecifiedAllDevices) {
      devices = <Device>[
        for (final Device device in devices)
          if (await device.targetPlatform != TargetPlatform.fuchsia_arm64 &&
              await device.targetPlatform != TargetPlatform.fuchsia_x64 &&
              await device.targetPlatform != TargetPlatform.web_javascript)
            device,
      ];
    }

    // If there is no specified device, the remove all devices which are not
    // supported by the current application. For example, if there was no
    // 'android' folder then don't attempt to launch with an Android device.
    if (devices.length > 1 && !hasSpecifiedDeviceId) {
      devices = <Device>[
        for (final Device device in devices)
          if (isDeviceSupportedForProject(device, flutterProject))
            device,
      ];
    } else if (devices.length == 1 &&
             !hasSpecifiedDeviceId &&
             !isDeviceSupportedForProject(devices.single, flutterProject)) {
      // If there is only a single device but it is not supported, then return
      // early.
      return <Device>[];
    }

    // If there are still multiple devices and the user did not specify to run
    // all, then attempt to prioritize ephemeral devices. For example, if the
    // use only typed 'flutter run' and both an Android device and desktop
    // device are availible, choose the Android device.
    if (devices.length > 1 && !hasSpecifiedAllDevices) {
      // Note: ephemeral is nullable for device types where this is not well
      // defined.
      if (devices.any((Device device) => device.ephemeral == true)) {
        devices = devices
            .where((Device device) => device.ephemeral == true)
            .toList();
      }
    }
    return devices;
  }

  /// Returns whether the device is supported for the project.
  ///
  /// This exists to allow the check to be overridden for google3 clients.
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    return device.isSupportedForProject(flutterProject);
  }
}

/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;

  /// Whether this device discovery is capable of listing any devices given the
  /// current environment configuration.
  bool get canListAnything;

  /// Return all connected devices, cached on subsequent calls.
  Future<List<Device>> get devices;

  /// Return all connected devices. Discards existing cache of devices.
  Future<List<Device>> discoverDevices({ Duration timeout });

  /// Gets a list of diagnostic messages pertaining to issues with any connected
  /// devices (will be an empty list if there are no issues).
  Future<List<String>> getDiagnostics() => Future<List<String>>.value(<String>[]);
}

/// A [DeviceDiscovery] implementation that uses polling to discover device adds
/// and removals.
abstract class PollingDeviceDiscovery extends DeviceDiscovery {
  PollingDeviceDiscovery(this.name);

  static const Duration _pollingInterval = Duration(seconds: 4);
  static const Duration _pollingTimeout = Duration(seconds: 30);

  final String name;
  ItemListNotifier<Device> _items;
  Timer _timer;

  Future<List<Device>> pollingGetDevices({ Duration timeout });

  void startPolling() {
    if (_timer == null) {
      _items ??= ItemListNotifier<Device>();
      _timer = _initTimer();
    }
  }

  Timer _initTimer() {
    return Timer(_pollingInterval, () async {
      try {
        final List<Device> devices = await pollingGetDevices(timeout: _pollingTimeout);
        _items.updateWithNewList(devices);
      } on TimeoutException {
        globals.printTrace('Device poll timed out. Will retry.');
      }
      _timer = _initTimer();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<List<Device>> get devices async {
    return _populateDevices();
  }

  @override
  Future<List<Device>> discoverDevices({ Duration timeout }) async {
    _items = null;
    return _populateDevices(timeout: timeout);
  }

  Future<List<Device>> _populateDevices({ Duration timeout }) async {
    _items ??= ItemListNotifier<Device>.from(await pollingGetDevices(timeout: timeout));
    return _items.items;
  }

  Stream<Device> get onAdded {
    _items ??= ItemListNotifier<Device>();
    return _items.onAdded;
  }

  Stream<Device> get onRemoved {
    _items ??= ItemListNotifier<Device>();
    return _items.onRemoved;
  }

  void dispose() => stopPolling();

  @override
  String toString() => '$name device discovery';
}

abstract class Device {
  Device(this.id, {@required this.category, @required this.platformType, @required this.ephemeral});

  final String id;

  /// The [Category] for this device type.
  final Category category;

  /// The [PlatformType] for this device.
  final PlatformType platformType;

  /// Whether this is an ephemeral device.
  final bool ephemeral;

  String get name;

  bool get supportsStartPaused => true;

  /// Whether it is an emulated device running on localhost.
  Future<bool> get isLocalEmulator;

  /// The unique identifier for the emulator that corresponds to this device, or
  /// null if it is not an emulator.
  ///
  /// The ID returned matches that in the output of `flutter emulators`. Fetching
  /// this name may require connecting to the device and if an error occurs null
  /// will be returned.
  Future<String> get emulatorId;

  /// Whether the device is a simulator on a platform which supports hardware rendering.
  Future<bool> get supportsHardwareRendering async {
    assert(await isLocalEmulator);
    switch (await targetPlatform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        return true;
      case TargetPlatform.ios:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      default:
        return false;
    }
  }

  /// Whether the device is supported for the current project directory.
  bool isSupportedForProject(FlutterProject flutterProject);

  /// Check if a version of the given app is already installed
  Future<bool> isAppInstalled(covariant ApplicationPackage app);

  /// Check if the latest build of the [app] is already installed.
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app);

  /// Install an app package on the current device
  Future<bool> installApp(covariant ApplicationPackage app);

  /// Uninstall an app package from the current device
  Future<bool> uninstallApp(covariant ApplicationPackage app);

  /// Check if the device is supported by Flutter
  bool isSupported();

  // String meant to be displayed to the user indicating if the device is
  // supported by Flutter, and, if not, why.
  String supportMessage() => isSupported() ? 'Supported' : 'Unsupported';

  /// The device's platform.
  Future<TargetPlatform> get targetPlatform;

  Future<String> get sdkNameAndVersion;

  /// Get a log reader for this device.
  ///
  /// If `app` is specified, this will return a log reader specific to that
  /// application. Otherwise, a global log reader will be returned.
  ///
  /// If `includePastLogs` is true and the device type supports it, the log
  /// reader will also include log messages from before the invocation time.
  /// Defaults to false.
  FutureOr<DeviceLogReader> getLogReader({
    covariant ApplicationPackage app,
    bool includePastLogs = false,
  });

  /// Get the port forwarder for this device.
  DevicePortForwarder get portForwarder;

  /// Clear the device's logs.
  void clearLogs();

  /// Optional device-specific artifact overrides.
  OverrideArtifacts get artifactOverrides => null;

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call. The build mode is not used by all platforms.
  Future<LaunchResult> startApp(
    covariant ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  });

  /// Whether this device implements support for hot reload.
  bool get supportsHotReload => true;

  /// Whether this device implements support for hot restart.
  bool get supportsHotRestart => true;

  /// Whether flutter applications running on this device can be terminated
  /// from the vmservice.
  bool get supportsFlutterExit => true;

  /// Whether the device supports taking screenshots of a running flutter
  /// application.
  bool get supportsScreenshot => false;

  /// Whether the device supports the '--fast-start' development mode.
  bool get supportsFastStart => false;

  /// Stop an app package on the current device.
  Future<bool> stopApp(covariant ApplicationPackage app);

  /// Query the current application memory usage..
  ///
  /// If the device does not support this callback, an empty map
  /// is returned.
  Future<MemoryInfo> queryMemoryInfo() {
    return Future<MemoryInfo>.value(const MemoryInfo.empty());
  }

  Future<void> takeScreenshot(File outputFile) => Future<void>.error('unimplemented');

  @nonVirtual
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => id.hashCode;

  @nonVirtual
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Device
        && other.id == id;
  }

  @override
  String toString() => name;

  static Stream<String> descriptions(List<Device> devices) async* {
    if (devices.isEmpty) {
      return;
    }

    // Extract device information
    final List<List<String>> table = <List<String>>[];
    for (final Device device in devices) {
      String supportIndicator = device.isSupported() ? '' : ' (unsupported)';
      final TargetPlatform targetPlatform = await device.targetPlatform;
      if (await device.isLocalEmulator) {
        final String type = targetPlatform == TargetPlatform.ios ? 'simulator' : 'emulator';
        supportIndicator += ' ($type)';
      }
      table.add(<String>[
        device.name,
        device.id,
        getNameForTargetPlatform(targetPlatform),
        '${await device.sdkNameAndVersion}$supportIndicator',
      ]);
    }

    // Calculate column widths
    final List<int> indices = List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map<int>((int i) => 0).toList();
    for (final List<String> row in table) {
      widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    for (final List<String> row in table) {
      yield indices.map<String>((int i) => row[i].padRight(widths[i])).join(' • ') + ' • ${row.last}';
    }
  }

  static Future<void> printDevices(List<Device> devices) async {
    await descriptions(devices).forEach(globals.printStatus);
  }

  static List<String> devicesPlatformTypes(List<Device> devices) {
    return devices
        .map(
          (Device d) => d.platformType.toString(),
        ).toSet().toList()..sort();
  }

  /// Convert the Device object to a JSON representation suitable for serialization.
  Future<Map<String, Object>> toJson() async {
    final bool isLocalEmu = await isLocalEmulator;
    return <String, Object>{
      'name': name,
      'id': id,
      'isSupported': isSupported(),
      'targetPlatform': getNameForTargetPlatform(await targetPlatform),
      'emulator': isLocalEmu,
      'sdk': await sdkNameAndVersion,
      'capabilities': <String, Object>{
        'hotReload': supportsHotReload,
        'hotRestart': supportsHotRestart,
        'screenshot': supportsScreenshot,
        'fastStart': supportsFastStart,
        'flutterExit': supportsFlutterExit,
        'hardwareRendering': isLocalEmu && await supportsHardwareRendering,
        'startPaused': supportsStartPaused,
      }
    };
  }

  /// Clean up resources allocated by device
  ///
  /// For example log readers or port forwarders.
  Future<void> dispose();
}

/// Information about an application's memory usage.
abstract class MemoryInfo {
  /// Const constructor to allow subclasses to be const.
  const MemoryInfo();

  /// Create a [MemoryInfo] object with no information.
  const factory MemoryInfo.empty() = _NoMemoryInfo;

  /// Convert the object to a JSON representation suitable for serialization.
  Map<String, Object> toJson();
}

class _NoMemoryInfo implements MemoryInfo {
  const _NoMemoryInfo();

  @override
  Map<String, Object> toJson() => <String, Object>{};
}

class DebuggingOptions {
  DebuggingOptions.enabled(
    this.buildInfo, {
    this.startPaused = false,
    this.disableServiceAuthCodes = false,
    this.dartFlags = '',
    this.enableSoftwareRendering = false,
    this.skiaDeterministicRendering = false,
    this.traceSkia = false,
    this.traceWhitelist,
    this.traceSystrace = false,
    this.endlessTraceBuffer = false,
    this.dumpSkpOnShaderCompilation = false,
    this.cacheSkSL = false,
    this.useTestFonts = false,
    this.verboseSystemLogs = false,
    this.hostVmServicePort,
    this.deviceVmServicePort,
    this.initializePlatform = true,
    this.hostname,
    this.port,
    this.webEnableExposeUrl,
    this.webUseSseForDebugProxy = true,
    this.webRunHeadless = false,
    this.webBrowserDebugPort,
    this.webEnableExpressionEvaluation = false,
    this.vmserviceOutFile,
    this.fastStart = false,
   }) : debuggingEnabled = true;

  DebuggingOptions.disabled(this.buildInfo, {
      this.initializePlatform = true,
      this.port,
      this.hostname,
      this.webEnableExposeUrl,
      this.webUseSseForDebugProxy = true,
      this.webRunHeadless = false,
      this.webBrowserDebugPort,
      this.cacheSkSL = false,
      this.traceWhitelist,
    }) : debuggingEnabled = false,
      useTestFonts = false,
      startPaused = false,
      dartFlags = '',
      disableServiceAuthCodes = false,
      enableSoftwareRendering = false,
      skiaDeterministicRendering = false,
      traceSkia = false,
      traceSystrace = false,
      endlessTraceBuffer = false,
      dumpSkpOnShaderCompilation = false,
      verboseSystemLogs = false,
      hostVmServicePort = null,
      deviceVmServicePort = null,
      vmserviceOutFile = null,
      fastStart = false,
      webEnableExpressionEvaluation = false;

  final bool debuggingEnabled;

  final BuildInfo buildInfo;
  final bool startPaused;
  final String dartFlags;
  final bool disableServiceAuthCodes;
  final bool enableSoftwareRendering;
  final bool skiaDeterministicRendering;
  final bool traceSkia;
  final String traceWhitelist;
  final bool traceSystrace;
  final bool endlessTraceBuffer;
  final bool dumpSkpOnShaderCompilation;
  final bool cacheSkSL;
  final bool useTestFonts;
  final bool verboseSystemLogs;
  /// Whether to invoke webOnlyInitializePlatform in Flutter for web.
  final bool initializePlatform;
  final int hostVmServicePort;
  final int deviceVmServicePort;
  final String port;
  final String hostname;
  final bool webEnableExposeUrl;
  final bool webUseSseForDebugProxy;

  /// Whether to run the browser in headless mode.
  ///
  /// Some CI environments do not provide a display and fail to launch the
  /// browser with full graphics stack. Some browsers provide a special
  /// "headless" mode that runs the browser with no graphics.
  final bool webRunHeadless;

  /// The port the browser should use for its debugging protocol.
  final int webBrowserDebugPort;

  /// Enable expression evaluation for web target
  final bool webEnableExpressionEvaluation;

  /// A file where the vmservice URL should be written after the application is started.
  final String vmserviceOutFile;
  final bool fastStart;

  bool get hasObservatoryPort => hostVmServicePort != null;
}

class LaunchResult {
  LaunchResult.succeeded({ this.observatoryUri }) : started = true;
  LaunchResult.failed()
    : started = false,
      observatoryUri = null;

  bool get hasObservatory => observatoryUri != null;

  final bool started;
  final Uri observatoryUri;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('started=$started');
    if (observatoryUri != null) {
      buf.write(', observatory=$observatoryUri');
    }
    return buf.toString();
  }
}

class ForwardedPort {
  ForwardedPort(this.hostPort, this.devicePort) : context = null;
  ForwardedPort.withContext(this.hostPort, this.devicePort, this.context);

  final int hostPort;
  final int devicePort;
  final Process context;

  @override
  String toString() => 'ForwardedPort HOST:$hostPort to DEVICE:$devicePort';

  /// Kill subprocess (if present) used in forwarding.
  void dispose() {
    if (context != null) {
      context.kill();
    }
  }
}

/// Forward ports from the host machine to the device.
abstract class DevicePortForwarder {
  /// Returns a Future that completes with the current list of forwarded
  /// ports for this device.
  List<ForwardedPort> get forwardedPorts;

  /// Forward [hostPort] on the host to [devicePort] on the device.
  /// If [hostPort] is null or zero, will auto select a host port.
  /// Returns a Future that completes with the host port.
  Future<int> forward(int devicePort, { int hostPort });

  /// Stops forwarding [forwardedPort].
  Future<void> unforward(ForwardedPort forwardedPort);

  /// Cleanup allocated resources, like forwardedPorts
  Future<void> dispose();
}

/// Read the log for a particular device.
abstract class DeviceLogReader {
  String get name;

  /// A broadcast stream where each element in the string is a line of log output.
  Stream<String> get logLines;

  /// Some logs can be obtained from a VM service stream.
  /// Set this after the VM services are connected.
  vm_service.VmService connectedVMService;

  @override
  String toString() => name;

  /// Process ID of the app on the device.
  int appPid;

  // Clean up resources allocated by log reader e.g. subprocesses
  void dispose();
}

/// Describes an app running on the device.
class DiscoveredApp {
  DiscoveredApp(this.id, this.observatoryPort);
  final String id;
  final int observatoryPort;
}

// An empty device log reader
class NoOpDeviceLogReader implements DeviceLogReader {
  NoOpDeviceLogReader(this.name);

  @override
  final String name;

  @override
  int appPid;

  @override
  vm_service.VmService connectedVMService;

  @override
  Stream<String> get logLines => const Stream<String>.empty();

  @override
  void dispose() { }
}

// A portforwarder which does not support forwarding ports.
class NoOpDevicePortForwarder implements DevicePortForwarder {
  const NoOpDevicePortForwarder();

  @override
  Future<int> forward(int devicePort, { int hostPort }) async => devicePort;

  @override
  List<ForwardedPort> get forwardedPorts => <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async { }

  @override
  Future<void> dispose() async { }
}
