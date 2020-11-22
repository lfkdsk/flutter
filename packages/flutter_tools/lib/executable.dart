// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/commands/dev.dart';

import 'runner.dart' as runner;
import 'src/base/context.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/template.dart';
// The build_runner code generation is provided here to make it easier to
// avoid introducing the dependency into google3. Not all build* packages
// are synced internally.
import 'src/base/terminal.dart';
import 'src/build_runner/mustache_template.dart';
import 'src/build_runner/resident_web_runner.dart';
import 'src/build_runner/web_compilation_delegate.dart';
import 'src/commands/analyze.dart';
import 'src/commands/assemble.dart';
import 'src/commands/attach.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/downgrade.dart';
import 'src/commands/drive.dart';
import 'src/commands/emulators.dart';
import 'src/commands/format.dart';
import 'src/commands/generate.dart';
import 'src/commands/generate_localizations.dart';
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
import 'src/commands/symbolize.dart';
import 'src/commands/test.dart';
import 'src/commands/train.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/commands/version.dart';
import 'src/features.dart';
import 'src/globals.dart' as globals;
import 'src/runner/flutter_command.dart';
import 'src/web/compile.dart';
import 'src/web/web_runner.dart';

// BD ADD: START
import 'src/commands/analyze_size.dart';
import 'src/commands/develop.dart';
import 'src/artifacts.dart';
import 'src/calculate_build_info.dart';
// END
/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<void> main(List<String> args) async {
  final bool veryVerbose = args.contains('-vv');
  final bool verbose = args.contains('-v') || args.contains('--verbose') || veryVerbose;

  final bool doctor = (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  final bool muteCommandLogging = (help || doctor) && !veryVerbose;
  final bool verboseHelp = help && verbose;
  final bool daemon = args.contains('daemon');
  final bool runMachine = (args.contains('--machine') && args.contains('run')) ||
                          (args.contains('--machine') && args.contains('attach'));

  // BD ADD: START
  final bool lite = args.contains('--lite');
  final bool liteGlobal = args.contains('--lite-global');
  final bool liteShareSkia = args.contains('--lite-share-skia');
  // flutter conditions
  final bool hasConditions = args.contains('--conditions');
  final bool dynamicart = args.contains('--dynamicart');

  int engineMode = ENGINE_NORMAL;
  if (lite) {
    engineMode |= ENGINE_LITE;
    print('Currently in lite mode...');
  }
  if (liteGlobal) {
    if(engineMode & ENGINE_LITE!=0){
      throw ArgumentError(" --lite-global can be used with --lite");
    }
    engineMode |= ENGINE_LITE_GLOBAL;
    print('Currently in lite global mode...');
  }
  if (liteShareSkia) {
    if(engineMode & ENGINE_LITE!=0 || engineMode & ENGINE_LITE_GLOBAL!=0){
      throw ArgumentError("--lite-share-skia can be used with --lite or --lite-global");
    }
    engineMode |= ENGINE_LITE_SHARE_SKIA;
    print('Currently in lite & share skia mode...');
  }
  if(dynamicart){
    engineMode |= ENGINE_DYNAMICART;
    print('Currently in dynamicart mode...');
  }
  setEngineMode(engineMode);

  // BD ADD: START
  if (args.contains('build')) {
    FlutterBuildInfo.instance.needReport =
        !args.contains('--debug') && !args.contains('--profile');
    FlutterBuildInfo.instance.isAot =
        (args.length >= 2 && args[1] == 'aot') || args.contains('aot');
    if (FlutterBuildInfo.instance.isAot &&
        (args.length >= 2 && args[1] == 'ios' || args.contains('ios')
            || args.contains('--target-platform=ios'))) {
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
      '.dart_tool/conditions',
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

  await runner.run(args, () => <FlutterCommand>[
    AnalyzeCommand(
      verboseHelp: verboseHelp,
      fileSystem: globals.fs,
      platform: globals.platform,
      processManager: globals.processManager,
      logger: globals.logger,
      terminal: globals.terminal,
      artifacts: globals.artifacts,
    ),
    // BD ADD:
    AnalyzeSizeCommand(),
    AssembleCommand(),
    AttachCommand(verboseHelp: verboseHelp),
    BuildCommand(verboseHelp: verboseHelp),
    ChannelCommand(verboseHelp: verboseHelp),
    CleanCommand(verbose: verbose),
    ConfigCommand(verboseHelp: verboseHelp),
    CreateCommand(),
    DaemonCommand(hidden: !verboseHelp),
    // BD ADD: START
    DevelopCommand(),
    DevCommand(),
    // END
    DevicesCommand(),
    DoctorCommand(verbose: verbose),
    DowngradeCommand(),
    DriveCommand(),
    EmulatorsCommand(),
    FormatCommand(),
    GenerateCommand(),
    GenerateLocalizationsCommand(
      fileSystem: globals.fs,
    ),
    InstallCommand(),
    LogsCommand(),
    MakeHostAppEditableCommand(),
    PackagesCommand(),
    PrecacheCommand(
      verboseHelp: verboseHelp,
      cache: globals.cache,
      logger: globals.logger,
      platform: globals.platform,
      featureFlags: featureFlags,
    ),
    RunCommand(verboseHelp: verboseHelp),
    ScreenshotCommand(),
    ShellCompletionCommand(),
    TestCommand(verboseHelp: verboseHelp),
    UpgradeCommand(),
    VersionCommand(),
    SymbolizeCommand(
      stdio: globals.stdio,
      fileSystem: globals.fs,
    ),
    // Development-only commands. These are always hidden,
    IdeConfigCommand(),
    InjectPluginsCommand(),
    TrainingCommand(),
    UpdatePackagesCommand(),
  ], verbose: verbose,
     muteCommandLogging: muteCommandLogging,
     verboseHelp: verboseHelp,
     overrides: <Type, Generator>{
       WebCompilationProxy: () => BuildRunnerWebCompilationProxy(),
       // The web runner is not supported in google3 because it depends
       // on dwds.
       WebRunnerFactory: () => DwdsWebRunnerFactory(),
       // The mustache dependency is different in google3
       TemplateRenderer: () => const MustacheTemplateRenderer(),
       Logger: () {
        final LoggerFactory loggerFactory = LoggerFactory(
          outputPreferences: globals.outputPreferences,
          terminal: globals.terminal,
          stdio: globals.stdio,
          timeoutConfiguration: timeoutConfiguration,
        );
        return loggerFactory.createLogger(
          daemon: daemon,
          machine: runMachine,
          verbose: verbose && !muteCommandLogging,
          windows: globals.platform.isWindows,
        );
       }
     });
}


/// An abstraction for instantiation of the correct logger type.
///
/// Our logger class hierarchy and runtime requirements are overly complicated.
class LoggerFactory {
  LoggerFactory({
    @required Terminal terminal,
    @required Stdio stdio,
    @required OutputPreferences outputPreferences,
    @required TimeoutConfiguration timeoutConfiguration,
    StopwatchFactory stopwatchFactory = const StopwatchFactory(),
  }) : _terminal = terminal,
       _stdio = stdio,
       _timeoutConfiguration = timeoutConfiguration,
       _stopwatchFactory = stopwatchFactory,
       _outputPreferences = outputPreferences;

  final Terminal _terminal;
  final Stdio _stdio;
  final TimeoutConfiguration _timeoutConfiguration;
  final StopwatchFactory _stopwatchFactory;
  final OutputPreferences _outputPreferences;

  /// Create the appropriate logger for the current platform and configuration.
  Logger createLogger({
    @required bool verbose,
    @required bool machine,
    @required bool daemon,
    @required bool windows,
  }) {
    Logger logger;
    if (windows) {
      logger = WindowsStdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        timeoutConfiguration: _timeoutConfiguration,
        stopwatchFactory: _stopwatchFactory,
      );
    } else {
      logger = StdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        timeoutConfiguration: _timeoutConfiguration,
        stopwatchFactory: _stopwatchFactory
      );
    }
    if (verbose) {
      logger = VerboseLogger(logger, stopwatchFactory: _stopwatchFactory);
    }
    if (daemon) {
      return NotifyingLogger(verbose: verbose, parent: logger);
    }
    if (machine) {
      return AppRunLogger(parent: logger);
    }
    return logger;
  }
}
