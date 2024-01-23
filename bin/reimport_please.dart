import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'package:reimport_please/src.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('dry-run', abbr: 'd', negatable: false);

  final List<String> arguments = parser.parse(args).arguments;
  if (arguments.contains('-h') || arguments.contains('--help')) {
    return help();
  }

  final bool dryRun =
      arguments.contains('-d') || arguments.contains('--dry-run');

  final String path = Directory.current.path;
  final String packageName =
      loadYaml(File('$path/pubspec.yaml').readAsStringSync())['name'];

  final stopwatch = Stopwatch();
  stopwatch.start();

  final sources = sourcesOf(Directory('$path/lib'));

  stdout.write('┏━━ Sorting ${sources.length} Dart files...');

  final List<File> sorted = [];

  for (final file in sources) {
    final result = sortImports(file.readAsLinesSync(), packageName);
    if (!result.updated) {
      continue;
    }

    if (dryRun) {
      sorted.add(file);
    } else {
      sorted.add(file..writeAsStringSync(result.sortedFile));
    }
  }

  stopwatch.stop();

  if (sorted.length > 1) {
    stdout.writeln();
  }

  for (int i = 0; i < sorted.length; i++) {
    final File file = sorted[i];

    stdout.write(
      '${sorted.length == 1 ? '\n' : ''}┃  ${i == sorted.length - 1 ? '┗' : '┣'}━━ ✔ Sorted imports for ${file.path.replaceFirst(path, '')}/',
    );

    stdout.writeln(file.path.split(Platform.pathSeparator).last);
  }

  if (sorted.isEmpty) {
    stdout.writeln();
  }

  stdout.writeln(
    '┗━━ ✔ Sorted ${sorted.length} files in ${stopwatch.elapsed.inSeconds}.${stopwatch.elapsedMilliseconds} seconds.',
  );

  if (dryRun) {
    if (sorted.isNotEmpty) {
      exit(1);
    }
  }
}
