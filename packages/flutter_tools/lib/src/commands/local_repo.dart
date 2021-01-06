import 'dart:async';

import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/globals.dart';

import '../runner/flutter_command.dart';

class LocalRepoCommand extends FlutterCommand {
  LocalRepoCommand() : super() {
    argParser
      ..addFlag('repo',
      help: 'Returns the local Maven repository for a local engine build.',)
      ..addOption(
      'mode',
      help: 'build mode.',
      )..addOption(
      'local-engine-path',
      help: 'local engine out path.',
    );
  }

  @override
  final String name = 'repo';

  @override
  final String description = 'Returns the local Maven repository for a local engine build.';


  @override
  Future<FlutterCommandResult> runCommand() async {
    final String result = getLocalEngineRepo(engineOutPath: stringArg('local-engine-path'),
        androidBuildMode: stringArg('mode'));
    if (result != null && result.isNotEmpty) {
      printStatus(result);
      return const FlutterCommandResult(ExitStatus.success);
    } else {
      return const FlutterCommandResult(ExitStatus.fail);
    }
  }
}
