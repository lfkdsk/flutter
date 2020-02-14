// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';
// BD ADD:
import '../calculate_build_info.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host. For producing deployment
/// .ipas, see https://flutter.dev/docs/deployment/ios.
class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand() {
    addBuildModeFlags(defaultToRelease: false);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    argParser
      ..addFlag('simulator',
        help: 'Build for the iOS simulator instead of the device.',
      )
      ..addFlag('codesign',
        defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).',
      )
      // BD ADD: START
      ..addFlag('compress-size',
        help: 'ios data 段拆包方案,只在release下生效,该参数只适用于ios,对android并不生效',
        negatable: false,
      );
    // TODO @王莹
//    Invalid argument(s): Duplicate option "lite".
//    #0      ArgParser._addOption (package:args/src/arg_parser.dart:294:7)
//    #1      ArgParser.addFlag (package:args/src/arg_parser.dart:132:5)
//    #2      new BuildIOSCommand (package:flutter_tools/src/commands/build_ios.dart:43:9)
//    #3      new BuildCommand (package:flutter_tools/src/commands/build.dart:28:19)
//    #4      main (package:flutter_tools/executable.dart:101:5)
//    #5      main (file:///Users/sunkun01/WorkCode/flutter/packages/flutter_tools/bin/flutter_tools.dart:8:3)
//    #6      _startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:305:32)
//    #7      _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174:12)
//      ..addFlag('lite',
//        negatable: false,
//        defaultsTo: false,
//        help: 'Flutter lite edition to reduce package size',
//      );
//    ..addFlag('lite-global',
//    negatable: false,
//    defaultsTo: false,
//    help: 'Flutter lite global edition to reduce package size',
//    );
      // END

  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  // BD MOD: START
  // @override
  // Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
  //   DevelopmentArtifact.universal,
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
    if (liteMode) {
      return const <DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
        DevelopmentArtifact.iOSLite,
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

    if (!platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on the Mac.');
    }

    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(TargetPlatform.ios) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final bool shouldCodesign = boolArg('codesign');

    if (!forSimulator && !shouldCodesign) {
      printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }
    final BuildInfo buildInfo = getBuildInfo();
    if (forSimulator && !buildInfo.supportsSimulator) {
      throwToolExit('${toTitleCase(buildInfo.friendlyModeName)} mode is not supported for simulators.');
    }

    final String logTarget = forSimulator ? 'simulator' : 'device';

    final String typeName = artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    printStatus('Building $app for $logTarget ($typeName)...');
    // BD ADD: START
    FlutterBuildInfo.instance.platform = 'ios';
    if (app != null) {
      FlutterBuildInfo.instance.pkgName = app.toString();
    }
    await FlutterBuildInfo.instance.reportInfo();
    // END
    final bool compressSize = buildInfo.mode == BuildMode.release
        ? boolArg('compress-size')
        : false;
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: !forSimulator,
      codesign: shouldCodesign,
      compressSize: compressSize
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result);
      throwToolExit('Encountered error while building for $logTarget.');
    }

    if (result.output != null) {
      printStatus('Built ${result.output}.');
    }

    return null;
  }
}
