import 'dart:io';
import 'package:git_hooks/git_hooks.dart';

void main(List<String> arguments) {
  // Explicitly match the strict function signature type required by the package
  Map<Git, Future<bool> Function()> params = {Git.preCommit: preCommit};

  GitHooks.call(arguments, params);
}

Future<bool> preCommit() async {
  print('Checking if your local branch is up-to-date with main...');

  // 1. Silent fetch from origin main
  ProcessResult fetchResult = await Process.run('git', [
    'fetch',
    'origin',
    'main',
  ]);
  if (fetchResult.exitCode != 0) {
    print('❌ Error: Failed to fetch from origin main.');
    return false;
  }

  // 2. Count how many commits main is ahead of your current local HEAD
  ProcessResult revListResult = await Process.run('git', [
    'rev-list',
    '--count',
    'HEAD..origin/main',
  ]);

  if (revListResult.exitCode == 0) {
    int commitsBehind = int.parse(revListResult.stdout.toString().trim());

    if (commitsBehind > 0) {
      print('\n❌ COMMIT DENIED!');
      print('Your branch is behind "main" by $commitsBehind commit(s).');
      print(
        'You must run "git merge origin/main" before committing new work.\n',
      );
      return false; // Blocks the commit
    }
  }

  print('✅ Branch is up-to-date. Proceeding with commit.');
  return true; // Allows the commit
}
