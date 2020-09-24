// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/project.dart';

import 'runner.dart' as runner;
import 'src/base/context.dart';

// The build_runner code generation is provided here to make it easier to
// avoid introducing the dependency into google3. Not all build* packages
// are synced internally.
import 'src/build_runner/build_runner.dart';
import 'src/build_runner/resident_web_runner.dart';
import 'src/build_runner/web_compilation_delegate.dart';

import 'src/codegen.dart';
import 'src/commands/analyze.dart';

// BD ADD:
import 'src/commands/analyze_size.dart';
import 'src/commands/assemble.dart';
import 'src/commands/attach.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';

// BD ADD:
import 'src/commands/develop.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/drive.dart';
import 'src/commands/emulators.dart';
import 'src/commands/format.dart';
import 'src/commands/generate.dart';
import 'src/commands/ide_config.dart';
import 'src/commands/inject_plugins.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/make_host_app_editable.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/shell_completion.dart';
import 'src/commands/test.dart';
import 'src/commands/train.dart';
import 'src/commands/unpack.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/commands/version.dart';
import 'src/runner/flutter_command.dart';
import 'src/web/compile.dart';
import 'src/web/web_runner.dart';

// BD ADD: START
import 'src/artifacts.dart';
import 'src/calculate_build_info.dart';

// END
/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<void> main(List<String> args) async {
  final bool verbose = args.contains('-v') || args.contains('--verbose');

  final bool doctor = (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help = args.contains('-h') ||
      args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') ||
      (args.length == 1 && verbose);
  final bool muteCommandLogging = help || doctor;
  final bool verboseHelp = help && verbose;
  // BD ADD: START
  final bool lite = args.contains('--lite');
  final bool liteGlobal = args.contains('--lite-global');
  final bool liteShareSkia = args.contains('--lite-share-skia');
  final bool hasConditions = args.contains('--conditions');

  EngineMode engineMode = EngineMode.normal;
  if (lite) {
    engineMode = EngineMode.lite;
    print('Currently in lite mode...');
  } else if (liteGlobal) {
    engineMode = EngineMode.lite_global;
    print('Currently in lite global mode...');
  } else if (liteShareSkia) {
    engineMode = EngineMode.lite_share_skia;
    print('Currently in lite & share skia mode...');
  }
  setEngineMode(engineMode);

  // BD ADD: START
  if (args.contains('build')) {
    FlutterBuildInfo.instance.needReport =
        !args.contains('--debug') && !args.contains('--profile');
    FlutterBuildInfo.instance.isAot =
        (args.length >= 2 && args[1] == 'aot') || args.contains('aot');
    if (FlutterBuildInfo.instance.isAot &&
        (args.length >= 2 && args[1] == 'ios' ||
            args.contains('ios') ||
            args.contains('--target-platform=ios'))) {
      FlutterBuildInfo.instance.platform = 'ios';
    }
    if (args.contains('--compress-size')) {
      FlutterBuildInfo.instance.useCompressSize = true;
    }
    FlutterBuildInfo.instance.isLite = lite || liteGlobal || liteShareSkia;
  }
  FlutterBuildInfo.instance.isVerbose = verbose;
  FlutterBuildInfo.instance.parseCommand(args);
  // print current command
  String cmdStr = '';
  for (String cmd in args) {
    cmdStr += ' ' + cmd;
  }
  print('current cmd: flutter $cmdStr');
  // END

  /**
   * BD ADD: START
   *    add bundle exec for pod install
   */
  if (args.contains('--bundler')) {
    args = List<String>.from(args); // dart didn't support this command
    args.removeWhere((String option) => option == '--bundler');
    Bundler.commandUsedBundler(); // we just need to know if exists
  }

  if (hasConditions) {
    final conditions = FlutterProject.current().directory.childFile(
          'build/conditions',
        );
    final allConditions = <String>[];
    if (conditions.existsSync()) {
      conditions.deleteSync();
    }
    conditions.createSync(recursive: true);
    args = List<String>.from(args); // dart didn't support this command
    final int index = args.indexWhere((String ele) => ele == '--conditions');
    if (index > 0 &&
        index + 1 < args.length &&
        args[index + 1].contains('condition')) {
      final String conFlag = args[index];
      final String conParams = args[index + 1];
      allConditions.add(conParams);
      // remove unsupported flag in flutter commands.
      args.removeRange(index, index + 2);
    }

    print('current conditions ${allConditions.join(', ')}');
    conditions.writeAsStringSync(allConditions.join(','), flush: true);
  }
  // END

  await runner.run(
      args,
      <FlutterCommand>[
        AnalyzeCommand(verboseHelp: verboseHelp),
        // BD ADD:
        AnalyzeSizeCommand(),
        AssembleCommand(),
        AttachCommand(verboseHelp: verboseHelp),
        BuildCommand(verboseHelp: verboseHelp),
        ChannelCommand(verboseHelp: verboseHelp),
        CleanCommand(),
        ConfigCommand(verboseHelp: verboseHelp),
        CreateCommand(),
        DaemonCommand(hidden: !verboseHelp),
        // BD ADD:
        DevelopCommand(),
        DevicesCommand(),
        DoctorCommand(verbose: verbose),
        DriveCommand(),
        EmulatorsCommand(),
        FormatCommand(),
        GenerateCommand(),
        IdeConfigCommand(hidden: !verboseHelp),
        InjectPluginsCommand(hidden: !verboseHelp),
        InstallCommand(),
        LogsCommand(),
        MakeHostAppEditableCommand(),
        PackagesCommand(),
        PrecacheCommand(verboseHelp: verboseHelp),
        RunCommand(verboseHelp: verboseHelp),
        ScreenshotCommand(),
        ShellCompletionCommand(),
        TestCommand(verboseHelp: verboseHelp),
        TrainingCommand(),
        UnpackCommand(),
        UpdatePackagesCommand(hidden: !verboseHelp),
        UpgradeCommand(),
        VersionCommand(),
      ],
      verbose: verbose,
      muteCommandLogging: muteCommandLogging,
      verboseHelp: verboseHelp,
      overrides: <Type, Generator>{
        // The build runner instance is not supported in google3 because
        // the build runner packages are not synced internally.
        CodeGenerator: () => const BuildRunner(),
        WebCompilationProxy: () => BuildRunnerWebCompilationProxy(),
        // The web runner is not supported internally because it depends
        // on dwds.
        WebRunnerFactory: () => DwdsWebRunnerFactory(),
      });
}
