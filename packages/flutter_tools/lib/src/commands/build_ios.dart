// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_tools/src/artifacts.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';
// BD ADD:
import '../calculate_build_info.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host. For producing deployment
/// .ipas, see https://flutter.dev/docs/deployment/ios.
class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand({ @required bool verboseHelp }) {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    addBuildModeFlags(defaultToRelease: true);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    // BD ADD:
    addDynamicartModeFlags();
    argParser
      ..addFlag('simulator',
        help: 'Build for the iOS simulator instead of the device. This changes '
          'the default build mode to debug if otherwise unspecified.',
      )
      ..addFlag('codesign',
        defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).',
      )
      // BD ADD: START
      ..addFlag('minimum-size',
          defaultsTo: false,
          help: '用于ios的dyamicart模式下减少包体积的参数'
      )
      ..addFlag('compress-size',
        help: 'ios data 段拆包方案,只在release下生效,该参数只适用于ios,对android并不生效',
        negatable: false,
      );
      // END

  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  // BD MOD: START
  // @override
  // Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
  //  DevelopmentArtifact.iOS,
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
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOSLite,
        DevelopmentArtifact.iOS,
      };
    } else {
      return const <DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
      };
    }
  }
  // END

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool forSimulator = boolArg('simulator');
    defaultBuildMode = forSimulator ? BuildMode.debug : BuildMode.release;

    if (!globals.platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on the Mac.');
    }

    final BuildInfo buildInfo = getBuildInfo();
    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(
      TargetPlatform.ios,
      buildInfo,
    ) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final bool shouldCodesign = boolArg('codesign');

    if (!forSimulator && !shouldCodesign) {
      globals.printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }
    if (forSimulator && !buildInfo.supportsSimulator) {
      throwToolExit('${toTitleCase(buildInfo.friendlyModeName)} mode is not supported for simulators.');
    }

    final String logTarget = forSimulator ? 'simulator' : 'device';

    final String typeName = globals.artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    globals.printStatus('Building $app for $logTarget ($typeName)...');

    // BD ADD: START
    FlutterBuildInfo.instance.platform = 'ios';
    if (app != null) {
      FlutterBuildInfo.instance.pkgName = app.toString();
    }
    await FlutterBuildInfo.instance.reportInfo();
    // END

    // BD ADD: START
    final bool isMinimumSize = (buildInfo.mode == BuildMode.release)
        ? boolArg('minimum-size')
        : false;
    List<String> dynamicPlugins;
    if (boolArg('dynamicart')) {
      dynamicPlugins = getDynamicPlugins();
    }

    // compressSize与minimums-ize互斥，优先minimum-size
    final bool compressSize = (!isMinimumSize && (buildInfo.mode == BuildMode.release))
        ? boolArg('compress-size')
        : false;
    // END

    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: !forSimulator,
      codesign: shouldCodesign,
      // BD ADD START:
      isDynamicart: (kEngineMode & ENGINE_DYNAMICART !=0),
      isMinimumSize: isMinimumSize,
      dynamicPlugins: dynamicPlugins,
      compressSize: compressSize
      // END
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result, globals.flutterUsage, globals.logger);
      throwToolExit('Encountered error while building for $logTarget.');
    }

    if (result.output != null) {
      globals.printStatus('Built ${result.output}.');
    }

    return FlutterCommandResult.success();
  }
}
