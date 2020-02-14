// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_builder.dart';
import '../build_info.dart';
import '../cache.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAppBundleCommand extends BuildSubCommand {
  BuildAppBundleCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addShrinkingFlag();

    argParser
      ..addFlag('track-widget-creation', negatable: false, hide: !verboseHelp)
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
  }

  @override
  final String name = 'appbundle';

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
    if (liteMode) {
      return const <DevelopmentArtifact>{
        DevelopmentArtifact.androidGenSnapshotLite,
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
  final String description =
      'Build an Android App Bundle file from your app.\n\n'
      'This command can build debug and release versions of an app bundle for your application. \'debug\' builds support '
      'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are '
      'suitable for deploying to app stores. \n app bundle improves your app size';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};

    usage[CustomDimensions.commandBuildAppBundleTargetPlatform] =
        stringsArg('target-platform').join(',');

    if (boolArg('release')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'release';
    } else if (boolArg('debug')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'debug';
    } else if (boolArg('profile')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'profile';
    } else {
      // The build defaults to release.
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'release';
    }
    return usage;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(getBuildInfo(),
      targetArchs: stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName),
      shrink: boolArg('shrink'),
    );
    await androidBuilder.buildAab(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
    );
    return null;
  }
}
