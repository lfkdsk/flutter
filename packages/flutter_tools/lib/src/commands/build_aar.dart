// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_builder.dart';
import '../android/gradle_utils.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand({ @required bool verboseHelp }) {
    argParser
      ..addFlag(
        'debug',
        defaultsTo: true,
        help: 'Build a debug version of the current project.',
      )
      ..addFlag(
        'profile',
        defaultsTo: true,
        help: 'Build a version of the current project specialized for performance profiling.',
      )
      ..addFlag(
        'release',
        defaultsTo: true,
        help: 'Build a release version of the current project.',
      );
    // BD ADD:
    addDynamicartModeFlags();
    addTreeShakeIconsFlag();
    usesFlavorOption();
    usesBuildNumberOption();
    usesPubOption();
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesTrackWidgetCreation(verboseHelp: false);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    argParser
      ..addMultiOption(
        'target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the project is compiled.',
      )
      ..addOption(
        'output-dir',
        help: 'The absolute path to the directory where the repository is generated. '
              "By default, this is '<current-directory>android/build'. ",
      );
  }

  @override
  final String name = 'aar';

  // BD MOD: START
  // @override
  // Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
  //   DevelopmentArtifact.androidGenSnapshot,
  // DevelopmentArtifact.universal,
  // };
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => getAdjustRequiredArtifacts();
  // END

  // BD ADD: START
  Set<DevelopmentArtifact> getAdjustRequiredArtifacts() {
    bool liteMode = false;
    if (argParser.options.containsKey('lite')) {
      liteMode = liteMode | boolArg('lite');
    }
    if (argParser.options.containsKey('lite-global')) {
      liteMode = liteMode | boolArg('lite-global');
    }
    if (argParser.options.containsKey('lite-share-skia')) {
      liteMode = liteMode | boolArg('lite-share-skia');
    }
    if (liteMode) {
      return const <DevelopmentArtifact>{
        DevelopmentArtifact.androidGenSnapshotLite,
        DevelopmentArtifact.androidGenSnapshot,
        DevelopmentArtifact.universal,
      };
    } else {
      return const <DevelopmentArtifact>{
        DevelopmentArtifact.androidGenSnapshot,
        DevelopmentArtifact.universal,
      };
    }
  }
  // END

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};
    final FlutterProject flutterProject = _getProject();
    if (flutterProject == null) {
      return usage;
    }
    if (flutterProject.manifest.isModule) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'module';
    } else if (flutterProject.manifest.isPlugin) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'plugin';
    } else {
      usage[CustomDimensions.commandBuildAarProjectType] = 'app';
    }
    usage[CustomDimensions.commandBuildAarTargetPlatform] = stringsArg('target-platform').join(',');
    return usage;
  }

  @override
  final String description = 'Build a repository containing an AAR and a POM file.\n\n'
      'By default, AARs are built for `release`, `debug` and `profile`.\n'
      'The POM file is used to include the dependencies that the AAR was compiled against.\n'
      'To learn more about how to use these artifacts, see '
      'https://flutter.dev/go/build-aar';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.androidSdk == null) {
      exitWithNoSdkMessage();
    }
    final Set<AndroidBuildInfo> androidBuildInfo = <AndroidBuildInfo>{};

    final Iterable<AndroidArch> targetArchitectures =
        stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName);

    final String buildNumber = argParser.options.containsKey('build-number')
      && stringArg('build-number') != null
      && stringArg('build-number').isNotEmpty
      ? stringArg('build-number')
      : '1.0';

//    for (final String buildMode in const <String>['debug', 'profile', 'release']) {
//      if (boolArg(buildMode)) {
//        androidBuildInfo.add(
//          AndroidBuildInfo(
//            getBuildInfo(forcedBuildMode: BuildMode.fromName(buildMode)),
//            targetArchs: targetArchitectures,
//          )
//        );
//      }
//    }
//    if (androidBuildInfo.isEmpty) {
//      throwToolExit('Please specify a build mode and try again.');
//    }

    void buildAndroidBuildInfo(bool f(String buildMode)){
      for (String buildMode in const <String>['debug', 'profile', 'release']) {
        if (f(buildMode)) {
          androidBuildInfo.add(
              AndroidBuildInfo(
                BuildInfo(BuildMode.fromName(buildMode), stringArg('flavor'),
                    // BD ADD: START
                    dynamicPlugins: getDynamicPlugins()?.join(","),
                    dynamicart: argParser.options.containsKey('dynamicart')
                        ? boolArg('dynamicart')
                        : false,
                    lite: argParser.options.containsKey('lite')
                        ? boolArg('lite')
                        : false,
                    liteGlobal: argParser.options.containsKey('lite-global')
                        ? boolArg('lite-global')
                        : false,
                    liteShareSkia: argParser.options.containsKey('lite-share-skia')
                        ? boolArg('lite-share-skia')
                        : false),
                targetArchs: targetArchitectures,
              )
          );
        }
      }
    }

    buildAndroidBuildInfo((String buildMode) => boolArg(buildMode));

    if (androidBuildInfo.isEmpty) {
      buildAndroidBuildInfo((String buildMode) => true);
    }
    // END

    await androidBuilder.buildAar(
      project: _getProject(),
      target: '', // Not needed because this command only builds Android's code.
      androidBuildInfo: androidBuildInfo,
      outputDirectoryPath: stringArg('output-dir'),
      buildNumber: buildNumber,
    );
    return FlutterCommandResult.success();
  }

  /// Returns the [FlutterProject] which is determined from the remaining command-line
  /// argument if any or the current working directory.
  FlutterProject _getProject() {
    if (argResults.rest.isEmpty) {
      return FlutterProject.current();
    }
    return FlutterProject.fromPath(findProjectRoot(argResults.rest.first));
  }
}
