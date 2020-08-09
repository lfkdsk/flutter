import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemEntity, Process;
import 'package:archive/archive.dart';

// ignore: implementation_imports
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide FileSystemEntity;
import 'package:flutter_tools/src/base/fingerprint.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/trans_support.dart';
import 'package:meta/meta.dart';
import '../artifacts.dart';
import '../asset.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../devfs.dart';
import '../flutter_manifest.dart';
import '../globals.dart';
import '../project.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

const String defaultManifestPath = 'pubspec.yaml';

class BuildDynamicCommand extends BuildSubCommand {
  BuildDynamicCommand() {
    //help: 'The main entry-point file of the application, as run on the device.\n'
    //            'If the --target option is omitted, but a file name is provided on '
    //            'the command line, then that is used instead.',
    usesTargetOption();
    usesPubOption();
    addDynamicModeFlags();
    argParser
      ..addOption('origin-resource',
          defaultsTo: '', help: 'aot模式下的资源的目录，文件目录组织形式和flutter_assets目录相同')
      ..addFlag('verbose', defaultsTo: false)
      ..addFlag('verify', defaultsTo: true)
      ..addFlag('encrypt', defaultsTo: true)
      ..addOption('manifest', defaultsTo: defaultManifestPath);
  }

  @override
  final String name = 'dynamic';

  @override
  final String description = '打patch包专属命令';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String originResource = stringArg('origin-resource');

    final String manifestPath = stringArg('manifest') ?? defaultManifestPath;
    final bool verbose = boolArg('verbose') ?? false;
    final bool verify = boolArg('verify') ?? true;
    final bool encrypt = boolArg('encrypt') ?? true;

    FlutterManifest flutterManifest;
    try {
      flutterManifest =
          await FlutterManifest.createFromPath(defaultManifestPath);
    } catch (e) {
      throwToolExit('Error detected in pubspec.yaml:');
    }

    final List<String> dynamicPlugins = getDynamicPlugins();
    final String hostDillPath = '${Cache.flutterRoot}/bin/internal/app.dill';

    final String packagesPath = fs.path.absolute('.packages');

    if (!fs.file(packagesPath).existsSync()) {
      throwToolExit('.packages 文件不存在');
    }
    final String outputPath = getPatchBuildDirectory();

    final Directory outputDirectory = fs.directory(getPatchBuildDirectory());
    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }

    final Directory buildDirectory = fs.directory(getBuildDirectory());
    if (buildDirectory.existsSync()) {
      buildDirectory.deleteSync(recursive: true);
    }

    final Directory tempDir =
        fs.directory(fs.path.join(getBuildDirectory(), 'temp'));

    await compileKernel(
        mainPath: findMainDartFile(targetFile),
        tempPath: tempDir.path,
        packagesPath: PackageMap.globalPackagesPath,
        outputPath: outputPath,
        trackWidgetCreation: false,
        dynamicPlugins: dynamicPlugins,
        verbose: verbose,
        hostDillPath: hostDillPath,
        encrypt: encrypt);

    final AssetBundle assets = await buildAssets(
      manifestPath: manifestPath,
      assetDirPath: getPatchAssetBuildDirectory(),
      packagesPath: fs.path.absolute(PackageMap.globalPackagesPath),
    );

    await assemble(
        assetBundle: assets,
        assetDirPath: getPatchAssetBuildDirectory(),
        originResource: originResource);

    final String packageName = flutterManifest.appName;
    final String versionCode = flutterManifest.appVersion;

    final Map<String, Map<String, String>> versionMap = <String, Map<String, String>>{};
    // 生成dynamicart的最大和最小版本号
    final String dynamicartVersion = Cache.instance.dynamicartRevision;
    final List<String> list = dynamicartVersion.split('.');
    final Map<String, String> dynamicartVersionJson = <String, String>{};
    final int majorVersion = int.parse(list[0]);
    final int minorVersion = int.parse(list[1]);
    dynamicartVersionJson['minVersion'] = '$majorVersion.$minorVersion.0';
    dynamicartVersionJson['maxVersion'] = '$majorVersion.${minorVersion + 1}.0';
    versionMap['dynamicart'] = dynamicartVersionJson;

    if (verify) {
      // 生成依赖的plugin的最大和最小版本号
      final Map<String, String> map = getPluginVersion(packagesPath);
      for (String key in map.keys) {
        final Map<String, String> version = Map();
        final List<String> list = map[key].split('.');

        final int majorVersion = int.parse(list[0]);
        final int minorVersion = int.parse(list[1]);

        version['minVersion'] = '$majorVersion.$minorVersion.0';
        version['maxVersion'] = '$majorVersion.${minorVersion + 1}.0';

        versionMap[key] = version;
      }
    }

    final Map<String, dynamic> jsonObject = <String, dynamic>{};
    jsonObject['packageName'] = packageName == null ? '' : packageName;
    jsonObject['version'] = versionCode == null ? '' : versionCode;
    jsonObject['dependencies'] = versionMap;
    final File manifestFile =
        fs.file(fs.path.join(getPatchBuildDirectory(), 'manifest.json'));
    manifestFile.writeAsStringSync(json.encode(jsonObject));
    final List<File> files = List();
    traverseFiles(getPatchBuildDirectory(), files);
    final Archive update = Archive();
    final Directory directory = fs.directory(outputPath);
    for (File file in files) {
      final String path =
          file.fileSystem.path.relative(file.path, from: directory.path);
      final List<int> bytes = file.readAsBytesSync();
      update.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    final File patchFile =
        fs.file(fs.path.join(getPatchBuildDirectory(), 'dynamic.zip'));

    patchFile
      ..createSync(recursive: true)
      ..writeAsBytesSync(ZipEncoder().encode(update), flush: true);
    print('build dynamic success');
  }
}

void traverseFiles(String path, List<File> list) {
  if (FileSystemEntity.isFileSync(path)) {
    list.add(fs.file(path));
  } else {
    final Directory directory = fs.directory(path);
    final List<FileSystemEntity> files = directory.listSync();
    for (FileSystemEntity f in files) {
      if (FileSystemEntity.isFileSync(f.path)) {
        list.add(fs.file(f.path));
      } else {
        traverseFiles(f.path, list);
      }
    }
  }
}

Future<bool> compileKernel({
  @required String mainPath,
  @required String packagesPath,
  @required String outputPath,
  @required String tempPath,
  @required bool trackWidgetCreation,
  List<String> extraFrontEndOptions = const <String>[],
  List<String> dynamicPlugins,
  bool verbose: false,
  String hostDillPath,
  bool encrypt: true
}) async {
  final Directory outputDir = fs.directory(outputPath);
  outputDir.createSync(recursive: true);
  //app.dill文件的临时目录
  final Directory tempDir =
      fs.directory(fs.path.join(getBuildDirectory(), 'temp'));

  tempDir.createSync(recursive: true);

  print('Compiling Dart to kernel: $mainPath');

  if ((extraFrontEndOptions != null) && extraFrontEndOptions.isNotEmpty)
    printTrace('Extra front-end options: $extraFrontEndOptions');

  final String depfilePath = fs.path.join(tempPath, 'kernel_compile.d');
  final CompilerOutput compilerOutput = await compile(
      sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath,
          mode: BuildMode.release),
      mainPath: mainPath,
      packagesPath: packagesPath,
      outputFilePath: getKernelPathForTransformerOptions(
        fs.path.join(tempPath, 'app.dill'),
        trackWidgetCreation: trackWidgetCreation,
      ),
      depFilePath: depfilePath,
      extraFrontEndOptions: extraFrontEndOptions,
      linkPlatformKernelIn: true,
      aot: true,
      trackWidgetCreation: trackWidgetCreation,
      targetProductVm: true,
      dynamicPlugins: dynamicPlugins,
      verbose: verbose,
      hostDillPath: hostDillPath
  );

  // Write path to frontend_server, since things need to be re-generated when that changes.
  final String frontendPath = artifacts
      .getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);
  await fs
      .directory(tempDir)
      .childFile('frontend_server.d')
      .writeAsString('frontend_server.d: $frontendPath\n');
  final String path = compilerOutput?.outputFilename;
  if (path == null) {
    throwToolExit('Compiler failed on $mainPath');
  }
  if (path != null && path.isNotEmpty) {
    final DevFSFileContent kernelContent =
        DevFSFileContent(fs.file(compilerOutput.outputFilename));

    final Directory flutterAssetPath =
        fs.directory(fs.path.join(outputPath, 'flutter_assets'));
    outputDir.createSync(recursive: true);
    File file;
    if (encrypt) {
      file =
          fs.file(fs.path.join(flutterAssetPath.path, 'kb'));
    } else {
      file =
          fs.file(fs.path.join(flutterAssetPath.path, 'kernel_blob.bin'));
    }

    file.parent.createSync(recursive: true);
    /// 加密标示用于兼容老版本
    if (encrypt) {
      await fs.file(fs.path.join(flutterAssetPath.path, 'encrypt.txt'))
          .writeAsString("123456789");
    }
    final List<int> kernelBlobContent = await kernelContent.contentsAsBytes();
    //异或加密
    if (encrypt) {
      _encrypt(kernelBlobContent);
    }
    await file.writeAsBytes(kernelBlobContent);
  }
  print('Compiling Dart to kernel Success');
  return true;
}

Future<void> assemble(
    {AssetBundle assetBundle,
    String privateKeyPath = defaultPrivateKeyPath,
    String assetDirPath,
    String compilationTraceFilePath,
    String originResource}) async {
  print('generate resources start');

  assetDirPath ??= getAssetBuildDirectory();
  ensureDirectoryExists(assetDirPath);

  final Map<String, DevFSContent> assetEntries =
      Map<String, DevFSContent>.from(assetBundle.entries);
  ensureDirectoryExists(assetDirPath);

  await writeBundle(fs.directory(assetDirPath), assetEntries, originResource);
  print('generate resources success');
}

Future<void> writeBundle(Directory bundleDir,
    Map<String, DevFSContent> assetEntries, String originResource) async {
  Directory directory;
  if (originResource == null || originResource.isNotEmpty) {
    directory = fs.directory(originResource);
  }

  File assetManifestJsonFile;
  File fontManifestJsonFile;
  if (directory != null && directory.existsSync()) {
    final List<FileSystemEntity> lister =
        fs.directory(originResource).listSync();
    for (FileSystemEntity entity in lister) {
      if (entity is File) {
        final String relativePath =
            fs.path.relative(entity.path, from: originResource);
        if (relativePath == assetManifestJson) {
          assetManifestJsonFile = entity;
        } else if (relativePath == fontManifestJson) {
          fontManifestJsonFile = entity;
        }
      }
    }
  }

  final List<String> assetList = List();
  if (assetManifestJsonFile != null) {
    final Map<String, List<dynamic>> jsonContent =
        Map<String, List<dynamic>>.from(
            json.decode(assetManifestJsonFile.readAsStringSync()) as Map);
    for (String key in jsonContent.keys) {
      final List<String> list = List();
      jsonContent[key].forEach((dynamic item) {
        list.add(item as String);
      });
      assetList.addAll(list);
    }
  }

  List<Font> list = List();
  final List<String> fontsList = List();
  if (fontManifestJsonFile != null) {
    list = parseFont(fontManifestJsonFile.readAsStringSync());
    for (Font font in list) {
      for (FontAsset asset in font.fontAssets) {
        fontsList.add(asset.assetUri.toString());
      }
    }
  }

  if (!bundleDir.existsSync()) {
    bundleDir.createSync(recursive: true);
  }

  bool isFontChange = false;
  bool isImageChange = false;

  await Future.wait<void>(assetEntries.entries
      .map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
    if (assetList.contains(entry.key)) {
      final File originFile = fs.file(fs.path.join(originResource, entry.key));
      final List<int> originContent = await originFile.readAsBytes();
      final List<int> content = await entry.value.contentsAsBytes();
      if (!isEqual(originContent, content)) {
        final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
        isImageChange = true;
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      }
    } else if (fontsList.contains(entry.key)) {
      final File originFile = fs.file(fs.path.join(originResource, entry.key));
      final List<int> originContent = await originFile.readAsBytes();
      final List<int> content = await entry.value.contentsAsBytes();
      if (!isEqual(originContent, content)) {
        isFontChange = true;
        final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(await entry.value.contentsAsBytes());
      }
    } else {
      if (entry.key.endsWith('.ttf')) {
        isFontChange = true;
      }
      isImageChange = true;
      final File file = fs.file(fs.path.join(bundleDir.path, entry.key));
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(await entry.value.contentsAsBytes());
    }
  }));
  if (!isFontChange) {
    final File file = fs.file(fs.path.join(bundleDir.path, fontManifestJson));
    file.deleteSync();
  }
  if (!isImageChange) {
    final File file = fs.file(fs.path.join(bundleDir.path, assetManifestJson));
    file.deleteSync();
  }
  final File file = fs.file(fs.path.join(bundleDir.path, license));
  if(file.existsSync()) {
    file.deleteSync();
  }
  final File manifestFile = fs.file(fs.path.join(bundleDir.path, hostManifest));
  if(manifestFile.existsSync()) {
    manifestFile.deleteSync();
  }
}

bool isEqual(List<int> originContent, List<int> content) {
  final Digest digest = md5.convert(content);
  final Digest originDigest = md5.convert(content);
  if (hex.encode(digest.bytes) == hex.encode(originDigest.bytes)) {
    return true;
  }
  return false;
}

List<Font> parseFont(String content) {
  if (content == null) {
    return null;
  }
  final List<Font> fonts = List();
  final List<Map<String, dynamic>> list =
      List<Map<String, dynamic>>.from(json.decode(content) as List);

  for (Map<String, dynamic> jsonContent in list) {
    String family;
    final List<FontAsset> fontAssets = List();

    for (String key in jsonContent.keys) {
      if (key == 'family') {
        family = jsonContent[key] as String;
      } else if (key == 'fonts') {
        final List<dynamic> fonts = jsonContent[key];
        for (Map<String, dynamic> item in fonts) {
          fontAssets.add(FontAsset(Uri.parse(item['asset'] as String),
              weight: item['weight'] as int, style: item['style'] as String));
        }
      }
    }
    fonts.add(Font(family, fontAssets));
  }
  return fonts;
}

Future<CompilerOutput> compile({
  String sdkRoot,
  String mainPath,
  String outputFilePath,
  String depFilePath,
  TargetModel targetModel = TargetModel.flutter,
  bool linkPlatformKernelIn = false,
  bool aot = false,
  @required bool trackWidgetCreation,
  List<String> extraFrontEndOptions,
  String packagesPath,
  List<String> fileSystemRoots,
  String fileSystemScheme,
  bool targetProductVm = false,
  String initializeFromDill,
  List<String> dynamicPlugins,
  bool verbose: false,
  String hostDillPath
}) async {
   final String frontendServer = artifacts
      .getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);

  FlutterProject flutterProject;
  if (fs.file('pubspec.yaml').existsSync()) {
    flutterProject = await FlutterProject.current();
  }

  // TODO(cbracken): eliminate pathFilter.
  // Currently the compiler emits buildbot paths for the core libs in the
  // depfile. None of these are available on the local host.
  Fingerprinter fingerprinter;
  if (depFilePath != null) {
    fingerprinter = Fingerprinter(
      fingerprintPath: '$depFilePath.fingerprint',
      paths: <String>[mainPath],
      properties: <String, String>{
        'entryPoint': mainPath,
        'trackWidgetCreation': trackWidgetCreation.toString(),
        'linkPlatformKernelIn': linkPlatformKernelIn.toString(),
        'engineHash': Cache.instance.engineRevision,
        'buildersUsed':
        '${flutterProject != null ? flutterProject.hasBuilders : false}',
      },
      depfilePaths: <String>[depFilePath],
      pathFilter: (String path) => !path.startsWith('/b/build/slave/'),
    );

    if (await fingerprinter.doesFingerprintMatch()) {
      printTrace('Skipping kernel compilation. Fingerprint match.');
      return CompilerOutput(outputFilePath, 0, /* sources */ null);
    }
  }

  // This is a URI, not a file path, so the forward slash is correct even on Windows.
  if (!sdkRoot.endsWith('/')) sdkRoot = '$sdkRoot/';
  final String engineDartPath =
  artifacts.getArtifactPath(Artifact.engineDartBinary);
  if (!processManager.canRun(engineDartPath)) {
    throwToolExit('Unable to find Dart binary at $engineDartPath');
  }
  final List<String> command = <String>[
    engineDartPath,
    frontendServer,
    '--sdk-root',
    sdkRoot,
    '--target=$targetModel',
    '--dynamic'
  ];
  if (trackWidgetCreation) command.add('--track-widget-creation');
  if (!linkPlatformKernelIn) command.add('--no-link-platform');
  if (aot) {
    command.add('--aot');
    command.add('--tfa');
  }
  if (verbose) {
    command.add('--verbose');
  }
  if (targetProductVm) {
    command.add('-Ddart.vm.product=true');
  }

  Uri mainUri;
  if (packagesPath != null) {
    command.addAll(<String>['--packages', packagesPath]);
    mainUri = PackageUriMapper.findUri(
        mainPath, packagesPath, fileSystemScheme, fileSystemRoots);
  }

  if (dynamicPlugins != null && dynamicPlugins.isNotEmpty) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < dynamicPlugins.length; i++) {
      buffer.write(dynamicPlugins[i]);
      if (i != dynamicPlugins.length - 1) {
        buffer.write(',');
      }
    }
    command.addAll(
        <String>['--dynamic-aot-plugins', buffer.toString()]);
  }

  if (outputFilePath != null) {
    command.addAll(<String>['--output-dill', outputFilePath]);
  }
  if (depFilePath != null &&
      (fileSystemRoots == null || fileSystemRoots.isEmpty)) {
    command.addAll(<String>['--depfile', depFilePath]);
  }
  if (fileSystemRoots != null) {
    for (String root in fileSystemRoots) {
      command.addAll(<String>['--filesystem-root', root]);
    }
  }
  if (fileSystemScheme != null) {
    command.addAll(<String>['--filesystem-scheme', fileSystemScheme]);
  }
  if (initializeFromDill != null) {
    command.addAll(<String>['--initialize-from-dill', initializeFromDill]);
  }

  if(hostDillPath != null && hostDillPath.isNotEmpty){
    command.addAll(<String>['--host-dill', hostDillPath]);
  }

  command.addAll(await TransformerHooks.getTransformerParams());

  if (extraFrontEndOptions != null) command.addAll(extraFrontEndOptions);

  command.add(mainUri?.toString() ?? mainPath);


  printTrace(command.join(' '));
  final Process server = await processManager
      .start(command)
      .catchError((dynamic error, StackTrace stack) {
    printError('Failed to start frontend server $error, $stack');
  });

  final StdoutHandler _stdoutHandler = StdoutHandler();

  server.stderr.transform<String>(utf8.decoder).listen(printError);
  server.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(_stdoutHandler.handler);
  final int exitCode = await server.exitCode;
  if (exitCode == 0) {
    if (fingerprinter != null) {
      await fingerprinter.writeFingerprint();
    }
    return _stdoutHandler.compilerOutput.future;
  }
  return null;
}

void _encrypt(List<int> data) {
  const int space = 8;
  final int spaceCount = data.length ~/ space;
  for (int i = 0; i < spaceCount; i++) {
    for (int j = 0; j < space; j++) {
      data[i * space + j] = data[i * space + j] ^ (i % space);
    }
  }
  for (int i = spaceCount * space; i < data.length; i++) {
    data[i] = data[i] ^ 2;
  }
}
