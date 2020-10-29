// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:package_config/packages_file.dart' as packages_file;
import 'package:yaml/yaml.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'cache.dart';
import 'globals.dart';
import 'project.dart';

const String unmatchDartKernelBinaryErrMsg =
    "Can't load Kernel binary: Invalid kernel binary format version.";
const String transformerTemplatePackageRelPath = '.';

/// Locate the Dart SDK.
String get dartSdkPath {
  return fs.path.join(Cache.flutterRoot, 'bin', 'cache', 'dart-sdk');
}

/// The required Dart language flags
const List<String> dartVmFlags = <String>[];

/// Return the platform specific name for the given Dart SDK binary. So, `pub`
/// ==> `pub.bat`. The default SDK location can be overridden with a specified
/// [sdkLocation].
String sdkBinaryName(String name, { String sdkLocation }) {
  return fs.path.absolute(fs.path.join(sdkLocation ?? dartSdkPath, 'bin', platform.isWindows ? '$name.bat' : name));
}


const String kPackagesFileName = '.packages';

Map<String, Uri> _parse(String packagesPath) {
  final List<int> source = fs.file(packagesPath).readAsBytesSync();
  return packages_file.parse(source,
      Uri.file(packagesPath, windows: platform.isWindows));
}

class PackageMap {
  PackageMap(this.packagesPath);

  static String get globalPackagesPath => _globalPackagesPath ?? kPackagesFileName;

  static String get globalGeneratedPackagesPath => fs.path.setExtension(globalPackagesPath, '.generated');

  static set globalPackagesPath(String value) {
    _globalPackagesPath = value;
  }

  static bool get isUsingCustomPackagesPath => _globalPackagesPath != null;

  static String _globalPackagesPath;

  final String packagesPath;

  /// Load and parses the .packages file.
  void load() {
    _map ??= _parse(packagesPath);
  }

  Map<String, Uri> get map {
    load();
    return _map;
  }
  Map<String, Uri> _map;

  /// Returns the path to [packageUri].
  String pathForPackage(Uri packageUri) => uriForPackage(packageUri).path;

  /// Returns the path to [packageUri] as URL.
  Uri uriForPackage(Uri packageUri) {
    assert(packageUri.scheme == 'package');
    final List<String> pathSegments = packageUri.pathSegments.toList();
    final String packageName = pathSegments.removeAt(0);
    final Uri packageBase = map[packageName];
    if (packageBase == null) {
      return null;
    }
    final String packageRelativePath = fs.path.joinAll(pathSegments);
    return packageBase.resolveUri(fs.path.toUri(packageRelativePath));
  }

  String checkValid() {
    if (fs.isFileSync(packagesPath)) {
      return null;
    }
    String message = '$packagesPath does not exist.';
    final String pubspecPath = fs.path.absolute(fs.path.dirname(packagesPath), 'pubspec.yaml');
    if (fs.isFileSync(pubspecPath)) {
      message += '\nDid you run "flutter pub get" in this directory?';
    } else {
      message += '\nDid you run this command from the same directory as your pubspec.yaml file?';
    }
    return message;
  }
}

class TransformerHooks {
  static String transformerSnapshot;

  static Future<bool> checkTransformerSnapshot({bool hasAop = true}) async {
    final PackageMap packageMap = PackageMap(
      fs.path.join(
        fs.currentDirectory.path,
        PackageMap.globalPackagesPath,
      ),
    );
    if (packageMap.map == null) {
      return false;
    }
    final String transLibPath =
    packageMap.map['transformer_template']?.toFilePath();
    if (transLibPath == null) {
      return false;
    }
    final String expectedTransformerSnapshotPath = fs.path.join(
        fs.directory(transLibPath).parent.path,
        'snapshot',
        'transformer_template.dart.snapshot');
    final File expectedTransformerSnapshot =
    fs.file(expectedTransformerSnapshotPath);
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
        return false;
      }
      transformerSnapshot = expectedTransformerSnapshotPath;
      return true;
    }

    return false;
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

  Future<void> justTransformDill(
      BuildMode buildMode,
      String outputFilename,
      ) async {
    final bool isEnable = await checkTransformerSnapshot(hasAop: false);
    if (!isEnable) {
      return;
    }
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
//    printStatus('Copy $originDill to $getDillPath}');
    fs.file(originDill).copySync(getDillPath());
  }

  static String getDillBuildDirectory() {
    return fs.path.join(getBuildDirectory(), 'dill');
  }

  static String getDillPath() =>
      '${getDillBuildDirectory()}${fs.path.separator}app.dill';

  static bool hasTransformer() {
    final YamlMap yaml =
    loadYaml(FlutterProject.current().pubspecFile.readAsStringSync())
    as YamlMap;
    return yaml['transformers'] != null;
  }

  static String getTransformerSnapshot() {
    return transformerSnapshot;
  }

  static List<String> getTransformerKeys() {
    return [];
  }

  static Future<List<String>> getTransformerParams() async {
    if (await TransformerHooks.checkTransformerSnapshot() &&
        TransformerHooks.getTransformerSnapshot() != null) {
      return Future.value([
        '--transformer',
        TransformerHooks.getTransformerSnapshot(),
        '--pubspec-file',
        FlutterProject.current().pubspecFile.absolute.path,
        '--dart-sdk',
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        if (getTransformerKeys().isNotEmpty) ...<String>[
          '--trans-keys',
          ...getTransformerKeys(),
        ]
      ]);
    }
    return Future<List<String>>.value(<String>[]);
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
        fs
            .file(artifacts.getArtifactPath(Artifact.platformKernelDill))
            .parent
            .path +
            fs.path.separator
      ],
      '--output',
      outputDill,
      '--pubspec',
      FlutterProject.current().pubspecFile.path,
      '--mode',
      buildMode.name,
    ];

    return processManager.run(command);
  }
}
