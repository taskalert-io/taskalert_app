import 'dart:io';
import 'package:git_hooks/git_hooks.dart';

void main(List<String> arguments) {
  // Explicitly match the strict function signature type required by the package
  Map<Git, Future<bool> Function()> params = {Git.preCommit: preCommit};

  GitHooks.call(arguments, params);
}

Future<bool> preCommit() async {
  // Using stdout.writeln forces the terminal stream to flush immediately on Windows
  stdout.writeln('Checking if your local branch is up-to-date with main...');

  // 1. Silent fetch from origin main
  ProcessResult fetchResult = await Process.run('git', [
    'fetch',
    'origin',
    'main',
  ]);
  if (fetchResult.exitCode != 0) {
    stdout.writeln('❌ Error: Failed to fetch from origin main.');
    return false;
  }

  // 2. Count how many commits main is ahead of your current local HEAD
  ProcessResult revListResult = await Process.run('git', [
    'rev-list',
    '--count',
    'HEAD..origin/main',
  ]);

  if (revListResult.exitCode == 0) {
    // CRITICAL FOR WINDOWS: Strips out non-numeric hidden shell artifacts like \r\n
    String cleanOutput = revListResult.stdout
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
    int commitsBehind = int.tryParse(cleanOutput) ?? 0;

    if (commitsBehind > 0) {
      stdout.writeln('\n❌ COMMIT DENIED!');
      stdout.writeln(
        'Your branch is behind "main" by $commitsBehind commit(s).',
      );
      stdout.writeln(
        'You must run "git merge origin/main" before committing new work.\n',
      );
      return false; // Blocks the commit
    }
  } else {
    stdout.writeln('❌ Error: Failed to evaluate branch synchronization state.');
    return false;
  }

  stdout.writeln('✅ Branch is up-to-date. Proceeding with commit.');
  return true; // Allows the commit
}
