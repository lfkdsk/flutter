import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as p;

const String kInstructionsSizesFileName = 'instructions.json';
const String kSnapshotSizesFileName = 'snapshots.json';
const String kV8SnapshotProfileFileName = 'v8.heapsnapshot';
const String kAnalyzeSizeOutputDirectory = 'build/analyze_size';

class AnalyzeSizeCommand extends FlutterCommand {
  AnalyzeSizeCommand() {
    argParser
      ..addOption(
        'target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios'],
      )
      ..addOption(kBase, help: 'Baseline package commit id.')
      ..addOption(kCompare, help: 'Compare package commit id.');
  }

  static const String kBase = 'base';
  static const String kCompare = 'compare';

  @override
  final String name = 'analyze-size';

  @override
  final String description = 'Bytedance Flutter SDK package size analyze tool.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> packageList = <String>[];

    final String base = stringArg(kBase);
    if (base == null) {
      throwToolExit('Missing baseline package commmit id.');
      return const FlutterCommandResult(ExitStatus.fail);
    } else {
      packageList.add(base);
    }

    final String current = stringArg(kCompare);
    if (current == null) {
      throwToolExit('Missing compare package commmit id.');
      return const FlutterCommandResult(ExitStatus.fail);
    } else {
      packageList.add(current);
    }

    final List<AnalyzeSizeModel> analyzeSizeModels = <AnalyzeSizeModel>[];
    for (int i = 0; i < packageList.length; i++) {
      final String packageCommitID = packageList[i];
      final String outputDirName =
          '$kAnalyzeSizeOutputDirectory/$packageCommitID';
      final Directory outputDir = Directory(outputDirName);
      await outputDir.create(recursive: true);

      final AnalyzeSizeModel model =
          await _buildPackage(packageCommitID, outputDirName);

      await model.analyze();

      analyzeSizeModels.add(model);
    }

    await (analyzeSizeModels[1] - analyzeSizeModels[0]);

    return const FlutterCommandResult(ExitStatus.success);
  }

  Future<AnalyzeSizeModel> _buildPackage(
      String commitID, String outputDirName) async {
    await processUtils.run(<String>['git', 'checkout', '-f', commitID]);

    final String targetPlatform = stringArg('target-platform');
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);

    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }

    final List<String> args = <String>[
      'build',
      'aot',
      '--suppress-analytics',
      '--release',
      '--target-platform=$targetPlatform',
      '--extra-gen-snapshot-options=--print_instructions_sizes_to=$outputDirName/$kInstructionsSizesFileName,--print_snapshot_sizes_to=$outputDirName/$kSnapshotSizesFileName,--write-v8-snapshot-profile-to=$outputDirName/$kV8SnapshotProfileFileName'
    ];

    if (platform == TargetPlatform.ios) {
      args.add('--ios-arch=arm64');
    }

    final FlutterCommandRunner runner = FlutterCommandRunner();
    runner.addCommand(BuildCommand());
    await runner.run(args);

    return AnalyzeSizeModel(outputDirName);
  }
}

class AnalyzeSizeModel {
  AnalyzeSizeModel(this.outputDirectory)
      : instructionsSizesFilePath =
            '$outputDirectory/$kInstructionsSizesFileName',
        snapshotSizesFilePath = '$outputDirectory/$kSnapshotSizesFileName',
        symbolCache = <String, int>{};

  static const String kindSymbol = 's';
  static const String kindPath = 'p';
  static const String kindBucket = 'b';
  static const String symbolTypeGlobalText = 'T';
  static const String kVMIsolateCodeSize = 'VMIsolate(CodeSize)';
  static const String kIsolateCodeSize = 'Isolate(CodeSize)';
  static const String kReadOnlyDataCodeSize = 'ReadOnlyData(CodeSize)';
  static const String kInstructionsCodeSize = 'Instructions(CodeSize)';
  static const String kTotalCodeSize = 'Total(CodeSize)';

  final String instructionsSizesFilePath;
  final String snapshotSizesFilePath;
  final String outputDirectory;
  final Map<String, int> symbolCache;
  Map<String, dynamic> snapshotSizes;

  Future<void> analyze() async {
    final File instructionsSizesFile = File(instructionsSizesFilePath);

    final List<dynamic> symbols = await instructionsSizesFile
        .openRead()
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first as List<dynamic>;

    final Map<String, dynamic> root = <String, dynamic>{
      'n': '',
      'children': <String, dynamic>{},
      'k': kindPath,
      'maxDepth': 0
    };

    for (dynamic item in symbols) {
      final Map<String, dynamic> symbol = item as Map<String, dynamic>;
      final String name = symbol['n'] as String;
      final int size = symbol['s'] as int;

      String key;
      if (symbol.containsKey('c')) {
        final String libraryUri = symbol['l'] as String;
        final String className = symbol['c'] as String;
        _addSymbol(root, '$libraryUri/$className', name, size);
        key = '$libraryUri/$className/${_modifyName(name)}';
      } else {
        _addSymbol(root, '@stubs', name, size);
        key = '@stubs/${_modifyName(name)}';
      }
      symbolCache[key] = (symbolCache[key] ?? 0) + size;
    }

    await _saveHtmlToDirectory(root, outputDirectory);

    final File snapshotSizesFile = File(snapshotSizesFilePath);
    snapshotSizes = await snapshotSizesFile
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first as Map<String, dynamic>;
  }

  Future<void> operator -(AnalyzeSizeModel model) async {
    final Status status = logger.startProgress(
      'Running package size analyze...',
      timeout: const TimeoutConfiguration().slowOperation,
    );

    final Map<String, int> increase = <String, int>{};
    final Map<String, int> decrease = <String, int>{};
    final Map<String, int> baseSymbolCache = model.symbolCache;
    symbolCache.forEach((String key, int value) {
      if (baseSymbolCache.containsKey(key)) {
        if (value > baseSymbolCache[key]) {
          increase[key] = value - baseSymbolCache[key];
        } else if (value < baseSymbolCache[key]) {
          decrease[key] = baseSymbolCache[key] - value;
        }
      } else {
        increase[key] = value;
      }
    });

    baseSymbolCache.forEach((String key, int value) {
      if (!symbolCache.containsKey(key)) {
        decrease[key] = value;
      }
    });

    await _saveInstructionsDiffResult(
        increase, '$kAnalyzeSizeOutputDirectory/diff/instructions_increase');
    await _saveInstructionsDiffResult(
        decrease, '$kAnalyzeSizeOutputDirectory/diff/instructions_decrease');

    final int totalSizeDiff = _intValue(snapshotSizes[kTotalCodeSize]) -
        _intValue(model.snapshotSizes[kTotalCodeSize]);

    final int instructionsSizeDiff =
        _intValue(snapshotSizes[kInstructionsCodeSize]) -
            _intValue(model.snapshotSizes[kInstructionsCodeSize]);

    final int dataSizeDiff = _intValue(snapshotSizes[kVMIsolateCodeSize]) -
        _intValue(model.snapshotSizes[kVMIsolateCodeSize]) +
        _intValue(snapshotSizes[kIsolateCodeSize]) -
        _intValue(model.snapshotSizes[kIsolateCodeSize]) +
        _intValue(snapshotSizes[kReadOnlyDataCodeSize]) -
        _intValue(model.snapshotSizes[kReadOnlyDataCodeSize]);

    await _saveJSONToFile(<String, int>{
      'total': totalSizeDiff,
      'instructions': instructionsSizeDiff,
      'data': dataSizeDiff
    }, '$kAnalyzeSizeOutputDirectory/diff/res.json');

    status.stop();
    printStatus(
        'Please check the analysis results in "$kAnalyzeSizeOutputDirectory".');
  }

  void _addSymbol(
      Map<String, dynamic> root, String path, String name, int size) {
    Map<String, dynamic> node = root;
    int depth = 0;
    for (String part in path.split('/')) {
      node = _addChild(node, kindPath, part) as Map<String, dynamic>;
      depth++;
    }
    node['lastPathElement'] = true;
    node = _addChild(node, kindBucket, symbolTypeGlobalText)
        as Map<String, dynamic>;
    node['t'] = symbolTypeGlobalText;
    node = _addChild(node, kindSymbol, name) as Map<String, dynamic>;
    node['t'] = symbolTypeGlobalText;
    node['value'] = size;
    depth += 2;
    root['maxDepth'] = max<int>(root['maxDepth'] as int, depth);
  }

  dynamic _addChild(Map<String, dynamic> node, String kind, String name) {
    return node['children'].putIfAbsent(name, () {
      final Map<String, dynamic> n = <String, dynamic>{'n': name, 'k': kind};
      if (kind != kindSymbol) {
        n['children'] = <String, dynamic>{};
      }
      return n;
    });
  }

  String _modifyName(String name) {
    final RegExp regexp = RegExp(r'0x[a-fA-F0-9]+');
    return name.replaceAll(regexp, '');
  }

  Future<void> _saveHtmlToDirectory(
      Map<String, dynamic> root, String outputDir) async {
    final Map<String, dynamic> tree = _flatten(root);

    final String templateRoot = p.join(Cache.flutterRoot, 'packages',
        'flutter_tools', 'templates', 'size_analysis');
    final String d3SrcDir = p.join(templateRoot, 'd3');
    final String templateDir = p.join(templateRoot, 'binary_size');

    final String d3OutDir = p.join(outputDir, 'd3');
    await Directory(d3OutDir).create(recursive: true);

    for (String file in <String>['LICENSE', 'd3.js']) {
      await _copyFile(d3SrcDir, file, d3OutDir);
    }
    for (String file in <String>['index.html', 'D3SymbolTreeMap.js']) {
      await _copyFile(templateDir, file, outputDir);
    }

    final String dataJsPath = p.join(outputDir, 'data.js');
    final IOSink sink = File(dataJsPath).openWrite();
    sink.write('var tree_data=');
    await sink.addStream(
        Stream<Object>.fromIterable(<Map<String, dynamic>>[tree])
            .transform(json.encoder.fuse(utf8.encoder)));
    await sink.close();
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> node) {
    dynamic children = node['children'];
    if (children != null) {
      children = children.values
          .map((dynamic v) => _flatten(v as Map<String, dynamic>))
          .toList();
      node['children'] = children;
      if (children.length == 1 && children.first['k'] == 'p') {
        final Map<String, dynamic> singleChild =
            children.first as Map<String, dynamic>;
        singleChild['n'] = '${node['n']}/${singleChild['n']}';
        return singleChild;
      }
    }
    return node;
  }

  Future<void> _copyFile(String fromDir, String name, String toDir) async {
    await File(p.join(fromDir, name)).copy(p.join(toDir, name));
  }

  Future<void> _saveInstructionsDiffResult(
      Map<String, int> diff, String outputDirName) async {
    final Map<String, dynamic> root = <String, dynamic>{
      'n': '',
      'children': <String, dynamic>{},
      'k': kindPath,
      'maxDepth': 0
    };

    diff.forEach((String key, int size) {
      final List<String> tmp = key.split('/');
      String path = '';
      for (int i = 0; i < tmp.length - 1; i++) {
        path += '${tmp[i]}/';
      }
      path = path.substring(0, path.length - 1);
      _addSymbol(root, path, tmp.last, size);
    });

    final Directory outputDir = Directory(outputDirName);
    await outputDir.create(recursive: true);
    await _saveHtmlToDirectory(root, outputDirName);

    final List<String> diffKeysBySize = diff.keys.toList();
    diffKeysBySize.sort((String a, String b) => diff[b] - diff[a]);
    final List<Map<String, dynamic>> jsonRes = <Map<String, dynamic>>[];
    for (String key in diffKeysBySize) {
      jsonRes.add(<String, dynamic>{'symbol': key, 'size': diff[key]});
    }

    await _saveJSONToFile(jsonRes, outputDirName + '/res.json');
  }

  Future<void> _saveJSONToFile(dynamic jsonRes, String outputFileName) async {
    final IOSink sink = File(outputFileName).openWrite();
    sink.write(json.encode(jsonRes));
    await sink.close();
  }

  int _intValue(dynamic value) => value as int;
}
