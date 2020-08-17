// BD ADD: START
import 'dart:async';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/version.dart';

import '../runner/flutter_command.dart';

class DevelopCommand extends FlutterCommand {
  DevelopCommand() {
    addSubcommand(DevelopInitCommand());
    addSubcommand(DevelopPublishCommand());
  }

  @override
  final String name = 'develop';

  @override
  final String description = 'Bytedance Flutter SDK development tools.';

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

class DevelopInitCommand extends FlutterCommand {
  DevelopInitCommand();

  @override
  final String name = 'init';

  @override
  final String description =
      'Init Bytedance Flutter SDK development environment.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Status status = logger.startProgress(
      'Running "flutter develop init" ...',
      timeout: const TimeoutConfiguration().slowOperation,
    );

    try {
      await processUtils.run(<String>['npm', '-v'], throwOnError: true);
    } catch (e) {
      status.stop();
      printError('Please install npm : brew install npm');
      printStatus('flutter develop init failed');

      return const FlutterCommandResult(ExitStatus.fail);
    }

    await processUtils.run(<String>['npm', 'install', '-g', 'commitizen']);
    await processUtils.run(<String>['npm', 'install'],
        workingDirectory: Cache.flutterRoot);

    status.stop();
    printStatus('flutter develop init succeed');

    return const FlutterCommandResult(ExitStatus.success);
  }
}

class DevelopPublishCommand extends FlutterCommand {
  DevelopPublishCommand() {
    argParser
      ..addOption('version',
          help: 'Bytedance Flutter SDK version number', valueHelp: 'X.Y.Z-H')
      ..addFlag(
        'republish',
        abbr: 'r',
        defaultsTo: false,
        negatable: false,
        help: 'Republish last version',
      );
  }

  @override
  final String name = 'publish';

  @override
  final String description = 'Publish Bytedance Flutter SDK.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool isRepublish = argResults['republish'] as bool;

    final Status status = logger.startProgress(
      'Running "flutter develop publish" ...',
      timeout: const TimeoutConfiguration().slowOperation,
    );
    if (isRepublish) {
      final RunResult commitRes = await processUtils.run(
          <String>['git', 'rev-list', '--tags', '--max-count=1'],
          workingDirectory: Cache.flutterRoot);
      final RunResult tagRes = await processUtils.run(
          <String>['git', 'describe', '--tags', '${commitRes.stdout.trim()}']);
      final String tag = tagRes.stdout.trim();
      await processUtils.run(<String>['git', 'tag', '-d', tag]);

      await processUtils.run(<String>[
        'git',
        'add',
        '.',
      ], workingDirectory: Cache.flutterRoot);
      await processUtils.run(<String>['git', 'commit', '--amend', '--no-edit'],
          workingDirectory: Cache.flutterRoot);

      await processUtils.run(<String>['git', 'tag', tag]);

      status.stop();
      printStatus('flutter develop publish succeed');
    } else {
      final String version =
          (argResults['version'] ?? BDGitTagVersion.determine(processUtils).nextVersion()) as String;

      final RunResult releaseRes = await processUtils.run(<String>[
        'npm',
        'run',
        'release',
        '--',
        '-t',
        'bd',
        '--release-as',
        '$version'
      ], workingDirectory: Cache.flutterRoot);
      final RegExp tipPattern = RegExp(r'Run (.*) to publish');
      final String regRes =
          tipPattern.firstMatch(releaseRes.stdout)?.group(0)?.toLowerCase();
      status.stop();
      printStatus(
          "Please check the CHANGELOG.md.\nIf OK, please $regRes ${BDGitTagVersion.determine(processUtils)}.\nIf not, please modify the CHANGELOG.md, and Run 'flutter develop publish -r', "
          'at last $regRes ${BDGitTagVersion.determine(processUtils)}.\n');
      printStatus('flutter develop publish succeed');
    }

    return const FlutterCommandResult(ExitStatus.success);
  }
}
// END
