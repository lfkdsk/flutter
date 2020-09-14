// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';

import '../aot.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../ios/bitcode.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// Builds AOT snapshots into platform specific library containers.
class BuildAotCommand extends BuildSubCommand with TargetPlatformBasedDevelopmentArtifacts {
  BuildAotCommand({bool verboseHelp = false, this.aotBuilder}) {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    usesDartDefines();
    // BD ADD:
    addDynamicartModeFlags();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios', 'android-x64'],
      )
      ..addFlag('quiet', defaultsTo: false)
      ..addFlag('report-timings',
        negatable: false,
        defaultsTo: false,
        help: 'Report timing information about build steps in machine readable form,',
      )
      // BD ADD: START
      ..addFlag('minimum-size',
        defaultsTo: false,
        help: '用于ios的dyamicart模式下减少包体积的参数')
      ..addFlag('compress-size',
        help: 'ios data 段拆包方案,只在release下生效,该参数只适用于ios,对android并不生效',
        negatable: false,)
      // END
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map<String>(getNameForDarwinArch),
        allowed: DarwinArch.values.map<String>(getNameForDarwinArch),
        help: 'iOS architectures to build.',
      )
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('bitcode',
        defaultsTo: kBitcodeEnabledDefault,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      );
    // --track-widget-creation is exposed as a flag here to deal with build
    // invalidation issues, but it is ignored -- there are no plans to support
    // it for AOT mode.
    usesTrackWidgetCreation(hasEffect: false, verboseHelp: verboseHelp);
  }

  AotBuilder aotBuilder;

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform');
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    final String outputPath = stringArg('output-dir') ?? getAotBuildDirectory();
    final BuildMode buildMode = getBuildMode();
    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }

    aotBuilder ??= AotBuilder();

    // BD ADD: START
    final bool compressSize = (buildMode == BuildMode.release) &&
        platform == TargetPlatform.ios
        ? boolArg('compress-size') && !boolArg('minimum-size')
        : false;
    List<String> dynamicPlugins;

    if (boolArg('dynamicart')) {
      dynamicPlugins = getDynamicPlugins();
    }
    final bool isMinimumSize = boolArg('dynamicart') ||
        buildMode == BuildMode.release
        ? boolArg('minimum-size') : false;
    // END

    await aotBuilder.build(
      platform: platform,
      outputPath: outputPath,
      buildMode: buildMode,
      mainDartFile: findMainDartFile(targetFile),
      bitcode: boolArg('bitcode'),
      quiet: boolArg('quiet'),
      // BD ADD: START
      trackWidgetCreation: boolArg('track-widget-creation'),
      useLite: boolArg('lite'),
      useLiteGlobal: boolArg('lite-global'),
      useLiteShareSkia: boolArg('lite-share-skia'),
      // END
      reportTimings: boolArg('report-timings'),
      iosBuildArchs: stringsArg('ios-arch').map<DarwinArch>(getIOSArchForName),
      extraFrontEndOptions: stringsArg(FlutterOptions.kExtraFrontEndOptions),
      extraGenSnapshotOptions: stringsArg(FlutterOptions.kExtraGenSnapshotOptions),
      dartDefines: dartDefines,
      // BD ADD: START
      isDynamicart: kEngineMode == EngineMode.dynamicart,
      dynamicPlugins: dynamicPlugins,
      compressSize: compressSize,
      isMinimumSize: isMinimumSize
      // END
    );
    return null;
  }
}
