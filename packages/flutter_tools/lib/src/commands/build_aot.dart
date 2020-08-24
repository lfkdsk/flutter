// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../aot.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../ios/bitcode.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// Builds AOT snapshots into platform specific library containers.
class BuildAotCommand extends BuildSubCommand with TargetPlatformBasedDevelopmentArtifacts {
  BuildAotCommand({this.aotBuilder}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();

    // BD ADD:
    addDynamicartModeFlags();

    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios', 'android-x64'],
      )
      ..addFlag('quiet', defaultsTo: false)
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
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('bitcode',
        defaultsTo: kBitcodeEnabledDefault,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      )
      ..addFlag('report-timings', hide: true);
  }

  AotBuilder aotBuilder;

  @override
  final String name = 'aot';

  // TODO(jonahwilliams): remove after https://github.com/flutter/flutter/issues/49562 is resolved.
  @override
  bool get deprecated => true;

  @override
  final String description = "(deprecated) Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform');
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    final String outputPath = stringArg('output-dir') ?? getAotBuildDirectory();
    final BuildInfo buildInfo = getBuildInfo();
    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }

    aotBuilder ??= AotBuilder();

    // BD ADD: START
    final bool compressSize = (buildInfo.mode == BuildMode.release || buildInfo.mode == BuildMode.dynamicartRelease) &&
        platform == TargetPlatform.ios
        ? boolArg('compress-size') && !boolArg('minimum-size')
        : false;
    List<String> dynamicPlugins;

    if (boolArg('dynamicart')) {
      dynamicPlugins = getDynamicPlugins();
    }
    final bool isMinimumSize = boolArg('dynamicart') ||
        buildInfo.mode == BuildMode.release
        ? boolArg('minimum-size') : false;
    // END

    await aotBuilder.build(
      platform: platform,
      outputPath: outputPath,
      buildInfo: buildInfo,
      mainDartFile: findMainDartFile(targetFile),
      bitcode: boolArg('bitcode'),
      quiet: boolArg('quiet'),
      iosBuildArchs: stringsArg('ios-arch').map<DarwinArch>(getIOSArchForName),
      reportTimings: boolArg('report-timings'),

      // BD ADD: START
      compressSize: compressSize,
      // trackWidgetCreation: boolArg('track-widget-creation'),
      useLite: boolArg('lite'),
      useLiteGlobal: boolArg('lite-global'),
      useLiteShareSkia: boolArg('lite-share-skia'),
      isDynamicart: buildInfo.mode == BuildMode.dynamicartRelease || buildInfo.mode == BuildMode.dynamicartProfile,
      dynamicPlugins: dynamicPlugins,
      isMinimumSize: isMinimumSize
      // END
    );
    return FlutterCommandResult.success();
  }
}
