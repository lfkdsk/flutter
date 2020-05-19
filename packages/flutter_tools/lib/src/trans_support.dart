// BD ADD
import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'artifacts.dart';
import 'base/build.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/process_manager.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/exceptions.dart';
import 'build_system/targets/dart.dart';
import 'bundle.dart';
import 'cache.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'dart/sdk.dart';
import 'globals.dart';
import 'project.dart';
import 'runner/flutter_command.dart';

class TransformerHooks {
  static String unmatchDartKernelBinaryErrMsg =
      "Can't load Kernel binary: Invalid kernel binary format version.";
  static String transformerTemplatePackageRelPath = '.';
  static String transformerTemplatePackageName = 'transformer_impl';

  static String transformerSnapshot;

  static Directory getTransDirectory(Directory rootProjectDir) {
    return fs.directory(
      fs.path.normalize(
        fs.path.join(
          rootProjectDir.path,
          transformerTemplatePackageRelPath,
          transformerTemplatePackageName,
        ),
      ),
    );
  }

  static Future<void> checkTransformerSnapshot({bool hasAop = true}) async {
    final PackageMap packageMap = PackageMap(
      fs.path.join(
        hasAop
            ? getTransDirectory(fs.currentDirectory).path
            : fs.currentDirectory.path,
        PackageMap.globalPackagesPath,
      ),
    );
    if (packageMap.map == null) {
      return;
    }
    final String transLibPath =
        packageMap.map['transformer_template']?.toFilePath();
    if (transLibPath == null) {
      return;
    }
    final String expectedTransformerSnapshotPath = fs.path.join(
        fs.directory(transLibPath).parent.path,
        'snapshot',
        'transformer_template.dart.snapshot');
    final File expectedTransformerSnapshot =
        fs.file(expectedTransformerSnapshotPath);
    final String expectedDartSha = getExpectedDartSha();
    final String transPubspecPath = fs.path.join(
      fs.directory(transLibPath).parent.path,
      'pubspec.yaml',
    );
    final String defaultDartSha = getDartShaFromPubspec(transPubspecPath);
    if (defaultDartSha == null || expectedDartSha == null) {
      return;
    }
    if (defaultDartSha != expectedDartSha) {
      if (expectedTransformerSnapshot.existsSync()) {
        expectedTransformerSnapshot.deleteSync();
      }
      final File transPubspecFile = fs.file(transPubspecPath);
      final String transPubspecContent = transPubspecFile
          .readAsStringSync()
          .replaceAll(defaultDartSha, expectedDartSha);
      transPubspecFile.writeAsStringSync(
        transPubspecContent,
        flush: true,
      );
    }
    if (!expectedTransformerSnapshot.existsSync()) {
      await generateTransformerSnapshot(expectedTransformerSnapshotPath);
    }
    if (expectedTransformerSnapshot.existsSync()) {
      final List<String> command = <String>[
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        expectedTransformerSnapshotPath,
      ];
      final ProcessResult result = await processManager.run(command);
      final String outputStr = result.stderr.toString().trim();
      if (outputStr == unmatchDartKernelBinaryErrMsg) {
        fs.file(expectedTransformerSnapshotPath).deleteSync();
        return;
      }
      transformerSnapshot = expectedTransformerSnapshotPath;
    }
  }

  static String getExpectedDartSha() {
    final File engineVersionFile = fs.file(fs.path
        .join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk', 'revision'));
    final String engineVersion = engineVersionFile.readAsStringSync().trim();
    return engineVersion;
  }

  static String getDartShaFromPubspec(String pubspecFilePath) {
    final File pubspecFile = fs.file(pubspecFilePath);
    final String pubspecContent = pubspecFile.readAsStringSync();
    final RegExp kernelItemReg = RegExp(
        r'(\s+kernel\s*\:)(\s+git\s*\:)(\s+[a-z]+\s*\:.*)(\s+[a-z]+\s*\:.*)(\s+[a-z]+\s*\:.*)');
    final Match matches = kernelItemReg.firstMatch(pubspecContent);
    if (matches == null) {
      return null;
    }
    final String matchItem = matches.group(0);
    final RegExp kernelRefReg = RegExp(r'ref\s*\:\s*[0-9a-z]+');
    return kernelRefReg.firstMatch(matchItem).group(0).split(':')[1].trim();
  }

  static Future<void> generateTransformerSnapshot(
      String transSnapshotPath) async {
    final Directory snapshotDir = fs.file(transSnapshotPath).parent;
    if (!snapshotDir.existsSync()) {
      fs.directory(snapshotDir).createSync(recursive: true);
    }
    final File pubspecLockFile = fs.file(
      fs.path.join(snapshotDir.parent.path, 'pubspec.lock'),
    );
    if (pubspecLockFile.existsSync()) {
      pubspecLockFile.deleteSync();
    }
    await processManager.run(
      <String>[sdkBinaryName('pub'), 'get', '--verbosity=warning'],
      workingDirectory: snapshotDir.parent.path,
      environment: <String, String>{'FLUTTER_ROOT': Cache.flutterRoot},
    );
    await processManager.run(
      <String>[
        sdkBinaryName('dart'),
        '--snapshot=snapshot/transformer_template.dart.snapshot',
        'bin/runner.dart'
      ],
      workingDirectory: snapshotDir.parent.path,
    );
  }

  static Future<bool> isAopEnabled() async {
    final Directory transDirectory = getTransDirectory(fs.currentDirectory);
    if (!(transDirectory.existsSync() &&
        fs.file(fs.path.join(transDirectory.path, 'pubspec.yaml'))
            .existsSync() &&
        fs.file(fs.path
                .join(transDirectory.path, PackageMap.globalPackagesPath))
            .existsSync() &&
        fs.file(fs.path.join(transDirectory.path, 'lib',
                transformerTemplatePackageName + '.dart'))
            .existsSync())) {
      return false;
    }
    await checkTransformerSnapshot();
    if (transformerSnapshot == null ||
        !fs.file(transformerSnapshot).existsSync()) {
      return false;
    } else {
      return true;
    }
  }

  Future<FlutterCommandResult> runBuildBundleDillCommand(
    FlutterCommand flutterCommand,
  ) async {
    final ArgResults argResults = flutterCommand.argResults;
    final String targetPlatform = argResults['target-platform'] as String;
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }

    final BuildMode buildMode = flutterCommand.getBuildMode();
    final Directory mainDirectory = fs.currentDirectory;
    final Directory transLibrary = getTransDirectory(fs.currentDirectory);
    final String origAssetsDir = argResults['asset-dir'] as String;
    final String originKernelBlob =
        fs.path.join(origAssetsDir, 'kernel_blob.bin');
    if (!fs.file(originKernelBlob).existsSync()) {
      return null;
    }

    final String assetsDir =
        origAssetsDir.replaceAll(mainDirectory.path, transLibrary.path);
    final String assetKernelBlob = fs.path.join(assetsDir, 'kernel_blob.bin');
    final String mainPath = fs.path.join(
        transLibrary.path, 'lib', transformerTemplatePackageName + '.dart');
    final String transformedKernelFilePath =
        fs.path.join(assetsDir, 'app.dill.trans.dill');
    fs.currentDirectory = transLibrary;

    await BundleBuilder().build(
      platform: platform,
      buildMode: buildMode,
      mainPath: mainPath,
      manifestPath: argResults['manifest'] as String,
      depfilePath: argResults['depfile'] as String,
      privateKeyPath: argResults['private-key'] as String,
      assetDirPath: assetsDir,
      precompiledSnapshot: argResults['precompiled'] as bool,
      reportLicensedPackages: argResults['report-licensed-packages'] as bool,
      trackWidgetCreation: argResults['track-widget-creation'] as bool,
      extraFrontEndOptions:
          argResults[FlutterOptions.kExtraFrontEndOptions] as List<String>,
      extraGenSnapshotOptions:
          argResults[FlutterOptions.kExtraGenSnapshotOptions] as List<String>,
      fileSystemScheme: argResults['filesystem-scheme'] as String,
      fileSystemRoots: argResults['filesystem-root'] as List<String>,
    );

    if (!fs.file(assetKernelBlob).existsSync()) {
      fs.currentDirectory = mainDirectory;
      return null;
    }

    final ProcessResult result = await transformDill(
        buildMode, assetKernelBlob, transformedKernelFilePath);
    if (result.exitCode != 0) {
      fs.currentDirectory = mainDirectory;
      throwToolExit('Transformer terminated unexpectedly.');
      return null;
    }

    final File originKernelFile = fs.file(originKernelBlob);
    if (originKernelFile.existsSync()) {
      originKernelFile.deleteSync();
    }

    fs.file(transformedKernelFilePath).copySync(originKernelBlob);
    fs.currentDirectory = mainDirectory;
    return null;
  }

  Future<FlutterCommandResult> runBuildAOTDillCommand(
      TargetPlatform platform,
      String outputDir,
      BuildMode buildMode,
      List<String> extraFrontEndOptions,
      List<String> dartDefines) async {
    if (platform == null) {
      throwToolExit('Unknown platform: $platform');
    }

    final Directory mainDirectory = fs.currentDirectory;
    final Directory transDirectory = getTransDirectory(mainDirectory);
    String mainPath = fs.path.join(
        transDirectory.path, 'lib', transformerTemplatePackageName + '.dart');
    fs.currentDirectory = transDirectory;
    final AOTSnapshotter snapshotter = AOTSnapshotter();
    final String outputPath = (outputDir ?? getAotBuildDirectory())
        .replaceAll(mainDirectory.path, transDirectory.path);

    // Compile to kernel.
    mainPath = await snapshotter.compileKernel(
        platform: platform,
        buildMode: buildMode,
        mainPath: mainPath,
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: false,
        outputPath: outputPath,
        extraFrontEndOptions: extraFrontEndOptions,
        dartDefines: dartDefines);

    if (mainPath == null) {
      fs.currentDirectory = mainDirectory;
      throwToolExit('Compiler terminated unexpectedly.');
      return null;
    }

    if (!mainPath.startsWith(fs.currentDirectory.path)) {
      mainPath = fs.path.join(fs.currentDirectory.path, mainPath);
    }

    final String transformedKernelFilePath = mainPath + '.trans.dill';
    final String defaultKernelFilePath =
        mainPath.replaceAll(transDirectory.path, mainDirectory.path);

    final ProcessResult result = await transformDill(
      buildMode,
      mainPath,
      transformedKernelFilePath,
    );
    if (result.exitCode != 0) {
      fs.currentDirectory = mainDirectory;
      throwToolExit('Transformer terminated unexpectedly.');
      return null;
    }

    final File defaultKernelFile = fs.file(defaultKernelFilePath);
    if (defaultKernelFile.existsSync()) {
      defaultKernelFile.deleteSync();
    }
    fs.file(transformedKernelFilePath).copySync(defaultKernelFilePath);
    fs.currentDirectory = mainDirectory;
    return null;
  }

  Future<void> runKernelDillSnapshotCommand(
    KernelSnapshot kernelSnapshot,
    Environment originalEnvironment,
    String originalDill,
  ) async {
    final Directory mainDirectory = fs.currentDirectory;
    final Directory transDirectory = getTransDirectory(mainDirectory);
    fs.currentDirectory = transDirectory;

    final String outputDir =
        (originalEnvironment.outputDir.absolute.path ?? getAotBuildDirectory())
            .replaceAll(mainDirectory.path, transDirectory.path);

    final FlutterProject flutterProject = FlutterProject.current();
    final Environment environment = Environment(
        projectDir: flutterProject.directory,
        outputDir: fs.directory(outputDir),
        buildDir: flutterProject.directory
            .childDirectory('.dart_tool')
            .childDirectory('flutter_build'),
        defines: Map<String, String>.from(originalEnvironment.defines));

    final KernelCompiler compiler = await kernelCompilerFactory.create(
      FlutterProject.fromDirectory(transDirectory),
    );
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'kernel_snapshot');
    }
    if (environment.defines[kTargetPlatform] == null) {
      throw MissingDefineException(kTargetPlatform, 'kernel_snapshot');
    }
    final BuildMode buildMode =
        getBuildModeForName(environment.defines[kBuildMode]);
    final String targetFile = fs.path.join(
        transDirectory.path, 'lib', transformerTemplatePackageName + '.dart');
    final String packagesPath = transDirectory.childFile('.packages').path;
    final String targetFileAbsolute = fs.file(targetFile).absolute.path;
    // everything besides 'false' is considered to be enabled.
    final bool trackWidgetCreation =
        environment.defines[kTrackWidgetCreation] != 'false';
    final TargetPlatform targetPlatform =
        getTargetPlatformForName(environment.defines[kTargetPlatform]);

    TargetModel targetModel = TargetModel.flutter;
    if (targetPlatform == TargetPlatform.fuchsia_x64 ||
        targetPlatform == TargetPlatform.fuchsia_arm64) {
      targetModel = TargetModel.flutterRunner;
    }

    final CompilerOutput output = await compiler.compile(
      sdkRoot: artifacts.getArtifactPath(
        Artifact.flutterPatchedSdkPath,
        platform: targetPlatform,
        mode: buildMode,
      ),
      aot: buildMode != BuildMode.debug,
      buildMode: buildMode,
      trackWidgetCreation: trackWidgetCreation && buildMode == BuildMode.debug,
      targetModel: targetModel,
      outputFilePath: environment.buildDir.childFile('app.dill').path,
      packagesPath: packagesPath,
      linkPlatformKernelIn: buildMode != BuildMode.debug,
      mainPath: targetFileAbsolute,
      depFilePath: environment.buildDir.childFile('kernel_snapshot.d').path,
      dartDefines: parseDartDefines(environment),
    );

    if (output == null || output.errorCount != 0) {
      fs.currentDirectory = mainDirectory;
      throwToolExit('Compiler terminated unexpectedly.');
      return Future<void>(() {});
    }

    final String transformedKernelFilePath =
        output.outputFilename + '.trans.dill';
    final ProcessResult result = await transformDill(
        buildMode, output.outputFilename, transformedKernelFilePath);
    if (result.exitCode != 0) {
      fs.currentDirectory = mainDirectory;
      throwToolExit(
          'Transformer terminated unexpectedly.' + result.stderr.toString());
      return Future<void>(() {});
    } else {
      print(result.stdout.toString());
    }

    final File originalDillFile = fs.file(originalDill);
    if (originalDillFile.existsSync()) {
      originalDillFile.renameSync(originalDill + '.origin.dill');
    }
    fs.file(transformedKernelFilePath).copySync(originalDill);

    fs.currentDirectory = mainDirectory;
  }

  Future<void> justTransformDill(
    BuildMode buildMode,
    String outputFilename,
  ) async {
    await checkTransformerSnapshot(hasAop: false);
    final String originDill = outputFilename;
    final String transDill = '$outputFilename.trans.dill';
    final ProcessResult result = await transformDill(
      buildMode,
      originDill,
      transDill,
    );
    if (result.exitCode != 0) {
      throwToolExit(
        'Transformer terminated unexpectedly.' + result.stderr.toString(),
      );
      return Future<void>(() {});
    } else {
      print(result.stdout.toString());
    }
    final File originalDillFile = fs.file(originDill);
    if (originalDillFile.existsSync()) {
      originalDillFile.renameSync(outputFilename + '.origin.dill');
    }
    fs.file(transDill).copySync(originDill);
    fs.directory(getDillBuildDirectory()).createSync(recursive: true);
    fs.file(originDill).copySync(getDillPath());
  }

  static String getDillBuildDirectory() {
    return fs.path.join(getBuildDirectory(), 'dill');
  }

  static String getDillPath() =>
      '${getDillBuildDirectory()}${fs.path.separator}app.dill';

  static bool hasTransformer() {
    final YamlMap yaml = loadYaml(FlutterProject.current().pubspecFile.readAsStringSync()) as YamlMap;
    return yaml['transformers'] != null;
  }

  static Future<ProcessResult> transformDill(
    BuildMode buildMode,
    String inputDill,
    String outputDill,
  ) async {
    final List<String> command = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      transformerSnapshot,
      '--input',
      inputDill,
      if (buildMode != BuildMode.release) ...<String>[
        '--sdk-root',
        fs.file(artifacts.getArtifactPath(Artifact.platformKernelDill))
                .parent
                .path +
            fs.path.separator
      ],
      '--output',
      outputDill,
      '--pubspec',
      FlutterProject.current().pubspecFile.path,
    ];

    return processManager.run(command);
  }
}
// END