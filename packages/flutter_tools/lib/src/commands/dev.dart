import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tools/src/aot.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:http/http.dart';
import 'package:flutter_tools/executable.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';

/// BD ADD
/// 编译替换产物并上传手机目录
class DevCommand extends FlutterCommand {
  DevCommand() {
    addSubcommand(DevAndroidCommand());
    addSubcommand(DevIOSCommand());
  }

  @override
  String get description => 'ByteDance Flutter Mix Project DevTools';

  @override
  String get name => 'dev';

  @override
  Future<FlutterCommandResult> runCommand() => null;
}

class DevAndroidCommand extends FlutterCommand {
  DevAndroidCommand() {
    usesTargetOption();
    usesFlavorOption();
    addBuildModeFlags(defaultToRelease: false);
    addShrinkingFlag();
    addDynamicartModeFlags();

    argParser
      ..addOption('host-location',
          help:
              'Install or ReInstall apk form location, value is host apk downloadUrl or string:"local" ')
      ..addOption('plugin-location',
          help:
              'Push plugin from location, value is plugin apk url or string:"local')
      ..addOption('dynamic-package', help: 'Package name of dynamic zip')
      ..addOption('shell-dir', help: 'Path of shell project')
      ..addOption('host-package', help: 'Package name of host app')
      ..addMultiOption(
        'target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>[
          'android-arm',
          'android-arm64',
          'android-x86',
          'android-x64'
        ],
        help: 'The target platform for which the app is compiled.',
      )
      ..addOption('flutter-path', help: 'Executable for flutter')
      ..addFlag(
        'split-per-abi',
        negatable: false,
        help: 'Whether to split the APKs per ABIs. '
            'To learn more, see: https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',
      )
      ..addFlag(
        'machine',
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
            'and progress in machine friendly format.',
      );
    usesTrackWidgetCreation(verboseHelp: false);
  }

  AndroidDevice _device;
  String _hostPackageName;
  Directory _apkDir;

  @override
  String get description =>
      'ByteDance Flutter Mix Project DevTools For Android';

  @override
  String get name => 'android';

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    final Device device = await findTargetDevice();
    if (device == null) {
      throwToolExit('No device connected');
    }
    if (device is AndroidDevice) {
      _device = device;
    }
    if (_device == null) {
      throwToolExit('Android device not found');
    }
    _hostPackageName = stringArg('host-package');
    if (_hostPackageName?.isEmpty ?? true) {
      throwToolExit('--host-package not found');
    }
    Directory projectRoot = FlutterProject.current().directory;
    if (projectRoot.parent.childFile('pubspec.yaml').existsSync() &&
        projectRoot.parent.childDirectory('android').existsSync() &&
        projectRoot.parent.childDirectory('ios').existsSync() &&
        projectRoot.parent.childDirectory('lib').existsSync()) {
      projectRoot = projectRoot.parent;
    }
    _apkDir = projectRoot.childDirectory('android').childDirectory('apks');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    if (argResults.wasParsed('host-location')) {
      await _installApk();
    }
    if (argResults.wasParsed('plugin-location')) {
      await _pushPluginApk();
    }
    await _executeBuild();
    await _restartAppAndAttach();
    return const FlutterCommandResult(ExitStatus.success);
  }

  Future<void> _checkDownload(String url, Directory workingDir) async {
    if (url?.isEmpty ?? true) {
      return;
    }
    final File urlRecordFile = workingDir.childFile('url_record_file');
    bool needDownload;
    if (urlRecordFile.existsSync()) {
      final String urlRecord = urlRecordFile.readAsStringSync();
      if (urlRecord != url) {
        needDownload = true;
      } else {
        needDownload = false;
      }
    } else {
      needDownload = true;
    }
    if (!needDownload) {
      return;
    }
    if (!workingDir.existsSync()) {
      workingDir.createSync(recursive: true);
    }

    /// Start download
    print('Start download $url...');
    await processUtils.stream(<String>[
      'curl',
      '-O',
      url,
    ], workingDirectory: workingDir.path);
    urlRecordFile.writeAsStringSync(url);
  }

  Future<bool> _installApk() async {
    final Directory hostDir = _apkDir.childDirectory('host');
    final String hostLocation = stringArg('host-location');
    Directory workDir;
    if (hostLocation == 'local') {
      workDir = hostDir;
    } else {
      final String path = fs.path.join(FlutterProject.current().directory.path,
          '.flutterw/cache/run_cache/fast_run_support/dart_mode/host/');
      workDir = fs.directory(fs.path.normalize(path));
      await _checkDownload(hostLocation, workDir);
    }

    if (!workDir.existsSync()) {
      throwToolExit('Could not find host directory:${workDir.path}');
    }

    final List<FileSystemEntity> hostList = workDir.listSync();
    if (hostList?.isEmpty ?? true) {
      throwToolExit('No apk to install');
    }
    final FileSystemEntity entity = _getFirstApk(hostList);
    if (entity == null) {
      throwToolExit('No apk to install');
    }

    /// Install host apk
    final AndroidApk apkToInstall = AndroidApk.fromApk(entity as File);
    if (await _device.isAppInstalled(apkToInstall)) {
      print('Uninstalling old version...');
      await _device.uninstallApp(apkToInstall);
    }
    final bool result = await _device.installApp(apkToInstall);
    if (!result) {
      throwToolExit('Install host Failed');
    }
    return result;
  }

  Future<bool> _pushPluginApk() async {
    final Directory pluginDir = _apkDir.childDirectory('plugin');
    final String pluginLocation = stringArg('plugin-location');
    Directory workDir;
    if (pluginLocation == 'local') {
      workDir = pluginDir;
    } else {
      final String path = fs.path.join(FlutterProject.current().directory.path,
          '.flutterw/cache/run_cache/fast_run_support/dart_mode/plugin/');
      workDir = fs.directory(fs.path.normalize(path));
      await _checkDownload(pluginLocation, workDir);
    }

    if (!workDir.existsSync()) {
      throwToolExit('Could not find plugin directory:${workDir.path}');
    }

    /// push Plugin apk if exists
    final List<FileSystemEntity> pluginList = workDir.listSync();
    if (pluginList?.isEmpty ?? true) {
      throwToolExit('No plugin to push');
    }
    final FileSystemEntity entity = _getFirstApk(pluginList);
    if (entity == null) {
      throwToolExit('No plugin to push');
    }
    final String destDir =
        '/sdcard/Android/data/$_hostPackageName/files/.patchs/';
    await _device.createDirOnDevice(destDir);
    final bool result = await _device.pushFile(entity.path, destDir);
    if (!result) {
      throwToolExit('Push Plugin Failed');
    }
    return result;
  }

  FileSystemEntity _getFirstApk(List<FileSystemEntity> list) {
    for (FileSystemEntity entity in list) {
      if (entity.basename.endsWith('.apk')) {
        return entity;
      }
    }
    return null;
  }

  Future<void> _executeBuild() async {
    print('Start build...');
    final String dynamicPackage = stringArg('dynamic-package');
    int resultCode;
    if (dynamicPackage?.isNotEmpty ?? false) {
      resultCode = await _buildDynamic();
    } else {
      resultCode = await _buildApk(fs.currentDirectory.path);
    }
    if (resultCode != 0) {
      throwToolExit('Execute build error:$resultCode');
    }
  }

  Future<int> _buildDynamic() async {
    final String shellDir = stringArg('shell-dir');
    if (shellDir?.isNotEmpty ?? false) {
      print('Start build Shell project ...');
      final int result = await _buildApk(shellDir);
      if (result != 0) {
        throwToolExit('Execute shell error:$result');
      }
    }
    print('Build Shell project success, then build dynamic zip ...');
    return await processUtils.stream(<String>[
      _getFlutterPath(),
      'build',
      'dynamic',
      '--${getBuildMode().toString()}',
      '--package-name=${stringArg('dynamic-package')}',
      '--host-package=$_hostPackageName',
      if (deviceManager.hasSpecifiedDeviceId)
        '--device-id=${deviceManager.specifiedDeviceId}',
    ], workingDirectory: fs.currentDirectory.path, allowReentrantFlutter: true);
  }

  Future<int> _buildApk(String workingDir) async {
    final List<String> platforms = stringsArg('target-platform');
    String concatPlatforms = '';
    for (String platform in platforms) {
      concatPlatforms += platform + ',';
    }
    concatPlatforms = concatPlatforms.substring(0, concatPlatforms.length - 1);
    return await processUtils.stream(<String>[
      _getFlutterPath(),
      'build',
      'apk',
      '--${getBuildMode().toString()}',
      if (boolArg('dynamicart')) '--dynamicart',
      '--target-platform=$concatPlatforms',
      '--host-package=$_hostPackageName',
      if (boolArg('track-widget-creation')) '--track-widget-creation',
      '--target=${stringArg('target')}',
      if (stringArg('flavor')?.isNotEmpty ?? false)
        '--flavor=${stringArg('flavor')}',
      if (boolArg('shrink')) '--shrink',
      if (boolArg('split-per-abi')) '--split-per-abi',
      if (deviceManager.hasSpecifiedDeviceId)
        '--device-id=${deviceManager.specifiedDeviceId}',
    ], workingDirectory: workingDir, allowReentrantFlutter: true);
  }

  String _getFlutterPath() {
    return (stringArg('flutter-path')?.isNotEmpty ?? false)
        ? stringArg('flutter-path')
        : 'flutter';
  }

  Future<void> _restartAppAndAttach() async {
    await main(<String>[
      '--no-color',
      'run',
      if (boolArg('machine')) '--machine',
      if (boolArg('track-widget-creation')) '--track-widget-creation',
      '--device-id=${deviceManager.specifiedDeviceId}',
      '--start-paused',
      '--use-application-binary=${_getHostApk().path}',
      '--in-replace-mode',
      '--dart-define=flutter.inspector.structuredErrors=true',
      stringArg('target')
    ]);
  }

  FileSystemEntity _getHostApk() {
    final Directory hostDir = _apkDir.childDirectory('host');
    if (hostDir.existsSync()) {
      final List<FileSystemEntity> list = hostDir.listSync();
      if (list?.isNotEmpty ?? false) {
        final FileSystemEntity entity = _getFirstApk(list);
        if (entity != null) {
          return entity;
        }
      }
    } else {
      final String path = fs.path.join(FlutterProject.current().directory.path,
          '.flutterw/cache/run_cache/fast_run_support/dart_mode/host/');
      final Directory workDir = fs.directory(fs.path.normalize(path));
      if (workDir.existsSync()) {
        final List<FileSystemEntity> list = workDir.listSync();
        if (list?.isNotEmpty ?? false) {
          final FileSystemEntity entity = _getFirstApk(list);
          if (entity != null) {
            return entity;
          }
        }
      }
    }
    throwToolExit(
        'Do not find hostApk anyWhere, have you set the hostLocation parameters correctly?');
  }
}

class DevIOSCommand extends FlutterCommand {
  DevIOSCommand() {
    usesPubOption();
    usesDartDefines();
    usesTargetOption();
    addBuildModeFlags(defaultToRelease: false);
    usesTrackWidgetCreation(verboseHelp: false);
    argParser
      ..addOption('host-location',
          help: 'IPA path where to find ipa and be deployed to devices'
      )
      ..addOption('device-type',
          help: 'Device type that use to get arch'
      )
      ..addOption('device-id',
          help: 'Device id.'
      )
      ..addOption('device-name',
          help: 'Device name.'
      )
      ..addFlag('machine',
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
            'and progress in machine friendly format.',
      )
      ..addFlag('dynamicart',
          help: 'Product App.framework that include dynamic function',
          defaultsTo: false,
          negatable: true)
      ..addFlag('universal',
          help: 'Produce universal frameworks that include all valid architectures. '
              'This is true by default.',
          defaultsTo: true,
          negatable: true
      )
      ..addFlag('xcframework',
        help: 'Produce xcframeworks that include all valid architectures (Xcode 11 or later).',
      );
  }

  @override
  String get description => 'ByteDance Flutter Mix Project DevTools For iOS';

  @override
  String get name => 'ios';

  FlutterProject _project;
  List<Device> _devices;
  AotBuilder aotBuilder;
  BundleBuilder bundleBuilder;

  BuildMode get buildMode {
    if (boolArg('debug')) {
      return BuildMode.debug;
    }
    if (boolArg('profile')) {
      return BuildMode.profile;
    }
    if (boolArg('release')) {
      return BuildMode.release;
    }
    return BuildMode.debug;
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    deviceManager.specifiedDeviceId = stringArg('device-id');
    _devices = await findAllTargetDevices();
    if (_devices == null) {
      throwToolExit('No device connected');
    }
    _project = FlutterProject.current();
    if (!_project.isModule) {
      throwToolExit('Building frameworks for iOS is only supported from a module.');
    }

    if (!platform.isMacOS) {
      throwToolExit('Building frameworks for iOS is only supported on the Mac.');
    }
  }

  String _changeUrlByArch(String url) {
    final String prefix = fs.path.dirname(url);
    if (_isSimulator()) {
      url = prefix + '/iphonesimulator.ipa';
    } else {
      url = prefix + '/iphoneos.ipa';
    }
    return url;
  }

  Future<void> _checkDownload(String url, Directory workingDir) async {
    if ((url?.isEmpty ?? true) || url == 'local') {
      return;
    }

    if (!workingDir.existsSync()) {
      workingDir.createSync(recursive: true);
    }

    url = _changeUrlByArch(url);

    final File urlRecordFile = workingDir.childFile('url_record_file');
    bool needDownload = false;
    if (urlRecordFile.existsSync()) {
      final String urlRecord = urlRecordFile.readAsStringSync();
      if (urlRecord != url) {
        needDownload = true;
      } else {
        needDownload = false;
      }
    } else {
      needDownload = true;
    }

    if (needDownload == true) {
      /// Start download
      print('Start download $url...');
      await processUtils.stream(<String>[
        'curl',
        '-O',
        url,
      ], workingDirectory: workingDir.path);
      urlRecordFile.writeAsStringSync(url);
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    final String outputArgument = fs.path.join(fs.currentDirectory.path, 'build', 'ios', 'framework');
    final BuildableIOSApp iosProject = await applicationPackages.getPackageForPlatform(TargetPlatform.ios) as BuildableIOSApp;

    if (iosProject == null) {
      throwToolExit("Module's iOS folder missing");
    }

    final Directory outputDirectory = fs.directory(fs.path.normalize(outputArgument));

    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }

    aotBuilder ??= AotBuilder();
    bundleBuilder ??= BundleBuilder();

    final BuildMode mode = getBuildMode();
    print('Building framework for $iosProject in ${getNameForBuildMode(mode)} mode...');
    final String xcodeBuildConfiguration = toTitleCase(getNameForBuildMode(mode));
    final Directory modeDirectory = outputDirectory.childDirectory(xcodeBuildConfiguration);
    final Directory iPhoneBuildOutput = modeDirectory.childDirectory('iphoneos');
    final Directory simulatorBuildOutput = modeDirectory.childDirectory('iphonesimulator');

      // Copy Flutter.framework.
    await _produceFlutterFramework(outputDirectory, mode, iPhoneBuildOutput, simulatorBuildOutput, modeDirectory);

      // Build aot, create module.framework and copy.
    await _produceAppFramework(mode, iPhoneBuildOutput, simulatorBuildOutput, modeDirectory);

    final Status status = logger.startProgress(' └─Moving to ${fs.path.relative(modeDirectory.path)}', timeout: timeoutConfiguration.slowOperation);
    // Delete the intermediaries since they would have been copied into our
    // output frameworks.
    if (iPhoneBuildOutput.existsSync()) {
        iPhoneBuildOutput.deleteSync(recursive: true);
    }
    if (simulatorBuildOutput.existsSync()) {
      simulatorBuildOutput.deleteSync(recursive: true);
    }
    status.stop();

    printStatus('Frameworks written to ${outputDirectory.path}.');

    //替换当前IPA中的Frameworks进行重签名
    final String packagePath = await _prepareFile();
    print('PackagePath:$packagePath');
    final File package = fs.file(packagePath);
    final Directory productDirectory = fs.directory(package.parent);
    final String productName = package.basename;

    if (_isSimulator()) {
      await _replaceFramework(packagePath, modeDirectory);
    } else {
      await _codeSignHostApp(productDirectory, productName, modeDirectory);
    }
    await _deploySignedProduct(package);
    return null;
  }
  
  bool _isSimulator() {
    final String deviceType = stringArg('device-type').toLowerCase();
    return deviceType.contains('simulator');
  } 

  Future<String> _prepareFile() async {
    final String hostLocation = stringArg('host-location');
    final bool useLocalIpa = hostLocation == 'local';
    Directory workDir;
    String sdk = "";
    if (_isSimulator()) {
      sdk = "iphonesimulator";
    } else {
      sdk = "iphoneos";
    }

    if (useLocalIpa) {
      final String path = fs.path.join(_project.directory.path, 'ios/fast_run_support/local_app', sdk);
      workDir = fs.directory(fs.path.normalize(path));
    } else {
      final String path = fs.path.join(_project.directory.path, '.flutterw/cache/run_cache/fast_run_support/ios/remote_app', sdk);
      workDir = fs.directory(fs.path.normalize(path));
      await _checkDownload(hostLocation, workDir);
    }

    File ipaFile;
    for (FileSystemEntity entity in workDir.listSync()) {
      if (entity.basename.endsWith('.ipa')) {
        ipaFile = entity as File;
      }
    }
    if (ipaFile == null) {
      throwToolExit('${workDir.path} has no ipa');
    }
    final Directory unzipDir = _getCacheDir().childDirectory('unzip');
    print('Unzip file to ${unzipDir.path}');
    if (unzipDir.existsSync()) {
      await unzipDir.delete(recursive: true);
    }
    unzipDir.createSync(recursive: true);
    os.unzip(ipaFile, unzipDir);
    Directory appFile;
    for (FileSystemEntity entity in unzipDir.listSync(recursive: true)) {
      if (entity.basename.endsWith('.app')) {
        appFile = entity as Directory;
      }
    }
    return appFile.path;
  }

  Future<void> _replaceFramework(String bundlePath, Directory frameworks) async {
    final String targetPath = bundlePath + '/Frameworks/';
    final String frameworkPath = frameworks.path + '/';
    final List<String> mvCommand = <String>['cp', '-r', frameworkPath, targetPath];
    await processUtils.stream(
      mvCommand,
      allowReentrantFlutter: false,
    );
  }

  Future<void> _produceFlutterFramework(Directory outputDirectory, BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory modeDirectory) async {
    final Status status = logger.startProgress(' ├─Populating Flutter.framework...', timeout: timeoutConfiguration.fastOperation);
    final String engineCacheFlutterFrameworkDirectory = artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: mode);

    // Copy universal engine cache framework to mode directory.
    final String flutterFrameworkFileName = fs.path.basename(engineCacheFlutterFrameworkDirectory);
    final Directory fatFlutterFrameworkCopy = modeDirectory.childDirectory(flutterFrameworkFileName);
    copyDirectorySync(fs.directory(engineCacheFlutterFrameworkDirectory), fatFlutterFrameworkCopy);

    if (boolArg('xcframework')) {
      // Copy universal framework to variant directory.
      final Directory armFlutterFrameworkDirectory = iPhoneBuildOutput.childDirectory(flutterFrameworkFileName);
      final File armFlutterFrameworkBinary = armFlutterFrameworkDirectory.childFile('Flutter');
      final File fatFlutterFrameworkBinary = fatFlutterFrameworkCopy.childFile('Flutter');
      copyDirectorySync(fatFlutterFrameworkCopy, armFlutterFrameworkDirectory);

      // Create iOS framework.
      List<String> lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-remove', 'x86_64', '-output', armFlutterFrameworkBinary.path];

      await processUtils.run(
        lipoCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );

      // Create simulator framework.
      final Directory simulatorFlutterFrameworkDirectory = simulatorBuildOutput.childDirectory(flutterFrameworkFileName);
      final File simulatorFlutterFrameworkBinary = simulatorFlutterFrameworkDirectory.childFile('Flutter');
      copyDirectorySync(fatFlutterFrameworkCopy, simulatorFlutterFrameworkDirectory);

      lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-thin', 'x86_64', '-output', simulatorFlutterFrameworkBinary.path];

      await processUtils.run(
        lipoCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );

      // Create XCFramework from iOS and simulator frameworks.
      final List<String> xcframeworkCommand = <String>[
        'xcrun',
        'xcodebuild',
        '-create-xcframework',
        '-framework', armFlutterFrameworkDirectory.path,
        '-framework', simulatorFlutterFrameworkDirectory.path,
        '-output', modeDirectory
            .childFile('Flutter.xcframework')
            .path
      ];

      await processUtils.run(
        xcframeworkCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );
    }

    if (!boolArg('universal')) {
      fatFlutterFrameworkCopy.deleteSync(recursive: true);
    }
    status.stop();
  }


  Future<void> _codeSignHostApp(Directory product, String productName, Directory frameworks) async {
    if (_isSimulator()) {
      printStatus('Device is simulator. No need to codesign.');
      return;
    }
    final String productPath = product.childFile(productName).path;
    final Map<String, String> config = await _fetchCertAndProfile(product);
    if (config['provision'] == null || config['developer'] == null) {
      throwToolExit('--could not found provision or developer');
    }
    final String codeSignPath = fs.path.join(Cache.flutterRoot,'packages', 'flutter_tools', 'bin');
    final String codeSignScript = fs.path.join(codeSignPath, 'sign.sh');
    final String developer = config['developer'];
    printStatus('Codesign with Developer $developer ...');
    final List<String> signCommand = <String>[codeSignScript, productPath, developer, config['provision'], frameworks.path];
    await processUtils.stream(
        signCommand,
        workingDirectory: product.path,
        allowReentrantFlutter: false
    );
    printStatus('Codesign succeed ...');
  }

  Future<void> _generateSessionToken() async {
    final int time = (DateTime.now().millisecondsSinceEpoch/1000).round();
    final int random = Random(100000000).nextInt(899999999);
    // ignore: prefer_adjacent_string_concatenation
    final Uint8List content = const Utf8Encoder().convert('$time' + '$random');
    final Digest digest = md5.convert(content);
    final String sessionId = hex.encode(digest.bytes);

    final List<String> browserCommand = <String>['open', 'https://cony.bytedance.net/debug_sh/login/$sessionId'];
    await processUtils.stream(
      browserCommand,
      allowReentrantFlutter: false,
    );

    int limit = 60;
    String token;
    while (limit > 0) {
      Map<String, String> param = {'session_id' : sessionId};
      final Map<String, dynamic> sessionRes = await _getURLContent('https://cony.bytedance.net/api/debug/user/login', param);
      if (sessionRes['success'] as bool) {
        token = sessionRes['successInfo']['token'] as String;
        break;
      } else {
        sleep(const Duration(seconds: 1));
        limit = limit - 1;
      }
    }
    if (token != null) {
      final File tokenFile = _getFileInCertDir('.cony_config');
      if (!tokenFile.existsSync()) {
        await tokenFile.create();
      }
      tokenFile.writeAsStringSync(token);
    }
  }

  Future<void> _registDevicePool(String udid, String deviceName) async {
    final File tokenFile = _getFileInCertDir('.cony_config');
    if (!tokenFile.existsSync()) {
      await _generateSessionToken();
    }
    String token = await tokenFile.readAsString();
    Map<String, String> param = {};
    param['scope'] = 'news';
    param['access_token'] = token;
    param['udid'] = udid;
    param['device_name'] = base64Encode(utf8.encode(deviceName));
    printStatus('Registering your device on AppStoreConnect, wait a moment...');
    String url = 'https://cony.bytedance.net/api/debug/device/add';
    Map<String, dynamic> registResponse = await _getURLContent(url, param);
    if (registResponse['success'] as bool && registResponse['successInfo'] as bool) {
      printStatus('Regist your device to device pool succeed,  begining debug now');
    } else {
      throwToolExit('Error registering your device, you can run debug.sh or try later');
    }
  }

  String _getDeviceId() {
    final String deviceId = stringArg('device-id');
    if (deviceId == null || deviceId.isEmpty) {
      return _devices.first.id;
    } else {
      return deviceId;
    }
  }

  String _getDeviceName() {
    final String deviceName = stringArg('device-name');
    if (deviceName == null || deviceName.isEmpty) {
      return _devices.first.name;
    } else {
      return deviceName;
    }
  }

  Future<Map<String, String>> _fetchCertAndProfile(Directory productDirectory) async {
    printStatus('Fetching certificate and profiles...');
    final String udid = _getDeviceId();
    final File developer = _getFileInCertDir('.$udid.developer');
    final File provision = _getFileInCertDir('.$udid.mobileprovision');
    final File cert = _getFileInCertDir('.$udid.p12');
    if (!developer.existsSync() || !provision.existsSync()) {
      final Map<String, dynamic> deviceRegisted = await _getURLContent('https://cony.bytedance.net/api/debug/device/team', {'udid':udid});
      final bool succeed = deviceRegisted['success'] as bool;
      if (!succeed) {
        final int errorCode = deviceRegisted['errorCode'] as int ;
        if (errorCode == 1001) {
          printStatus('This device is not registered, preparing for registration...');
          await _registDevicePool(udid, _getDeviceName());
        }
      }
      final Map<String, dynamic> assigned = deviceRegisted['successInfo'] as Map<String, dynamic>;
      final String accountId = assigned['account_id'] as String;
      final String debugCert = assigned['debug_cert_id'] as String;
      await developer.writeAsString(debugCert);

      //从cony获取Profile文件放置到Cert目录之下
      printStatus('Download Profiles...');
      final String provDownloadUri = 'https://cony.bytedance.net/api/debug/download/debug/prov?account_id=$accountId';
      final Uri uri = Uri.parse(provDownloadUri);
      await _downloadFile(uri, provision);

      //从cony获取证书内容，然后安装本地证书到电脑端
      final String certDownloadUri = 'https://cony.bytedance.net/api/debug/download/debug/cert?account_id=$accountId';
      final Uri certUri = Uri.parse(certDownloadUri);
      await _downloadFile(certUri, cert);
      final List<String> importCommand = <String>['security', 'import', cert.path, '-P', 'bytedance'];
      await processUtils.stream(
        importCommand,
        allowReentrantFlutter: false,
      );
    }
    final Map<String, String> codeSignMap = {};
    final String debugDevelop = await developer.readAsString();
    codeSignMap['developer'] = debugDevelop;
    codeSignMap['provision'] = provision.path;
    return codeSignMap;
  }

  Future<void> _deploySignedProduct(File product) async {
    final String bundlePath = product.path;
    final String deviceId = _getDeviceId();
    final String deviceName = _getDeviceName();
    printStatus('Deploy $bundlePath to $deviceName ...');
    printStatus('id $deviceId, bundle $bundlePath');
    await main(<String>[
      '--no-color',
      'run',
      if (boolArg('track-widget-creation')) '--track-widget-creation',
      '--device-id=$deviceId',
      '--use-application-binary=$bundlePath',
      '--in-replace-mode',
      if (boolArg('machine')) '--machine',
      '--dart-define=flutter.inspector.structuredErrors=true',
      stringArg('target')
    ]);
  }

  Future<Map<String, dynamic>> _getURLContent(String uri, Map<String, String> params) async {
    String absoluteUri = uri;
    if (params != null && params.isNotEmpty) {
      if (uri.contains('?')) {
        absoluteUri = uri + '&';
      } else {
        absoluteUri = uri + '?';
      }
      params.forEach((String key, String value) {
        absoluteUri = absoluteUri + '&' + '$key=$value';
      });
    }
    final Response response = await get(absoluteUri);
    final Map<String, dynamic> responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody;
  }

  Future<void> _downloadFile(Uri url, File location) async {
    final Directory directory = location.parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    await fetchUrl(url, destFile: location);
  }

  Future<void> _produceAppFramework(BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory modeDirectory) async {
    const String appFrameworkName = 'App.framework';
    final Directory destinationAppFrameworkDirectory = modeDirectory.childDirectory(appFrameworkName);
    destinationAppFrameworkDirectory.createSync(recursive: true);

    if (mode == BuildMode.debug) {
      final Status status = logger.startProgress(' ├─Add placeholder App.framework for debug...', timeout: timeoutConfiguration.fastOperation);
      await _produceStubAppFrameworkIfNeeded(mode, iPhoneBuildOutput, simulatorBuildOutput, destinationAppFrameworkDirectory);
      status.stop();
    } else {
      await _produceAotAppFrameworkIfNeeded(mode, iPhoneBuildOutput, destinationAppFrameworkDirectory);
    }

    //flutterw会在module的project目录下生成ios目录 && 部分工程不存在.ios目录
    File sourceInfoPlist = _project.ios.hostAppRoot.childDirectory('Flutter').childFile('AppFrameworkInfo.plist');
    if (!sourceInfoPlist.existsSync()) {
      sourceInfoPlist = _project.directory.childDirectory('.ios').childDirectory('Flutter').childFile('AppFrameworkInfo.plist');
    }
    final File destinationInfoPlist = destinationAppFrameworkDirectory.childFile('Info.plist')..createSync(recursive: true);
    destinationInfoPlist.writeAsBytesSync(sourceInfoPlist.readAsBytesSync());

    final Status status = logger.startProgress(' ├─Assembling Flutter resources for App.framework...', timeout: timeoutConfiguration.slowOperation);
    final bool isDyanmicArt = boolArg('dynamicart');
    await bundleBuilder.build(
      platform: TargetPlatform.ios,
      buildMode: mode,
      // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
      mainPath: fs.path.absolute(targetFile),
      assetDirPath: destinationAppFrameworkDirectory.childDirectory('flutter_assets').path,
      precompiledSnapshot: mode != BuildMode.debug,
      isDynamicart: isDyanmicArt,
      trackWidgetCreation: boolArg('track-widget-creation'),
    );
    status.stop();
  }

  Future<void> _produceStubAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory destinationAppFrameworkDirectory) async {
    if (mode != BuildMode.debug) {
      return;
    }
    const String appFrameworkName = 'App.framework';
    const String binaryName = 'App';

    final Directory iPhoneAppFrameworkDirectory = iPhoneBuildOutput.childDirectory(appFrameworkName);
    final File iPhoneAppFrameworkFile = iPhoneAppFrameworkDirectory.childFile(binaryName);
    await createStubAppFramework(iPhoneAppFrameworkFile, SdkType.iPhone);

    final Directory simulatorAppFrameworkDirectory = simulatorBuildOutput.childDirectory(appFrameworkName);
    final File simulatorAppFrameworkFile = simulatorAppFrameworkDirectory.childFile(binaryName);
    await createStubAppFramework(simulatorAppFrameworkFile, SdkType.iPhoneSimulator);

    final List<String> lipoCommand = <String>[
      'xcrun',
      'lipo',
      '-create',
      iPhoneAppFrameworkFile.path,
      simulatorAppFrameworkFile.path,
      '-output',
      destinationAppFrameworkDirectory.childFile(binaryName).path
    ];

    await processUtils.run(
      lipoCommand,
      allowReentrantFlutter: false,
    );
  }

  Future<void> _produceAotAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneBuildOutput, Directory destinationAppFrameworkDirectory) async {
    if (mode == BuildMode.debug) {
      return;
    }
    final Status status = logger.startProgress(' ├─Building Dart AOT for App.framework...', timeout: timeoutConfiguration.slowOperation);
    await aotBuilder.build(
      platform: TargetPlatform.ios,
      outputPath: iPhoneBuildOutput.path,
      buildMode: mode,
      // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
      mainDartFile: fs.path.absolute(targetFile),
      quiet: true,
      bitcode: false,
      reportTimings: false,
      iosBuildArchs: <DarwinArch>[DarwinArch.armv7, DarwinArch.arm64],
      dartDefines: dartDefines,
      trackWidgetCreation: boolArg('track-widget-creation'),
    );

    const String appFrameworkName = 'App.framework';
    copyDirectorySync(iPhoneBuildOutput.childDirectory(appFrameworkName), destinationAppFrameworkDirectory);
    status.stop();
  }

  File _getFileInCertDir(String fileName) {
    final Directory certDir = _getCacheDir().childDirectory('cert');
    if (!certDir.existsSync()) {
      certDir.createSync(recursive: true);
    }
    return certDir.childFile(fileName);
  }

  Directory _getCacheDir() {
    final Directory projectRoot = _project.directory;
    final String path = fs.path.join(projectRoot.path, '.flutterw/cache/run_cache/fast_run_support/ios/modified_app/HostOnlyDart');
    return fs.directory(fs.path.normalize(path));
  }
}
