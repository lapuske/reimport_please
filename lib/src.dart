import 'dart:io';

/// Prints the usage example to the [stdout].
void help() {
  print('Usage: dart run reimport_please');
  print('       --help, -h         Display this help command.');
  print('       --dry-run, -d         Dry run (no files will be written).');
}

/// Returns the [File]s of the [directory], if it exists.
Iterable<File> sourcesOf(Directory directory) {
  if (directory.existsSync()) {
    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.endsWith('.dart'));
  }

  return [];
}

/// Sort the imports
/// Returns the sorted file as a string at
/// index 0 and the number of sorted imports
/// at index 1
ImportSortData sortImports(
  List<String> lines,
  String packageName, {
  String? filePath,
}) {
  String dartImportComment(bool emojis) =>
      '//${emojis ? ' 🎯 ' : ' '}Dart imports:';
  String flutterImportComment(bool emojis) =>
      '//${emojis ? ' 🐦 ' : ' '}Flutter imports:';
  String packageImportComment(bool emojis) =>
      '//${emojis ? ' 📦 ' : ' '}Package imports:';
  String projectImportComment(bool emojis) =>
      '//${emojis ? ' 🌎 ' : ' '}Project imports:';

  final beforeImportLines = <String>[];
  final afterImportLines = <String>[];

  final dartImports = <String>[];
  final flutterImports = <String>[];
  final packageImports = <String>[];
  final projectRelativeImports = <String>[];
  final projectImports = <String>[];

  bool noImports() =>
      dartImports.isEmpty &&
      flutterImports.isEmpty &&
      packageImports.isEmpty &&
      projectImports.isEmpty &&
      projectRelativeImports.isEmpty;

  var isMultiLineString = false;

  for (var i = 0; i < lines.length; i++) {
    // Check if line is in multiline string
    if (_timesContained(lines[i], "'''") == 1 ||
        _timesContained(lines[i], '"""') == 1) {
      isMultiLineString = !isMultiLineString;
    }

    // If line is an import line
    if (lines[i].startsWith('import ') &&
        lines[i].endsWith(';') &&
        !isMultiLineString) {
      if (lines[i].contains('dart:')) {
        dartImports.add(lines[i]);
      } else if (lines[i].contains('package:flutter/')) {
        flutterImports.add(lines[i]);
      } else if (lines[i].contains('package:$packageName/')) {
        projectImports.add(lines[i].replaceFirst('package:$packageName', ''));
      } else if (lines[i].contains('package:')) {
        packageImports.add(lines[i]);
      } else {
        projectRelativeImports.add(lines[i]);
      }
    } else if (i != lines.length - 1 &&
        (lines[i] == dartImportComment(false) ||
            lines[i] == flutterImportComment(false) ||
            lines[i] == packageImportComment(false) ||
            lines[i] == projectImportComment(false) ||
            lines[i] == dartImportComment(true) ||
            lines[i] == flutterImportComment(true) ||
            lines[i] == packageImportComment(true) ||
            lines[i] == projectImportComment(true) ||
            lines[i] == '// 📱 Flutter imports:') &&
        lines[i + 1].startsWith('import ') &&
        lines[i + 1].endsWith(';')) {
    } else if (noImports()) {
      beforeImportLines.add(lines[i]);
    } else {
      afterImportLines.add(lines[i]);
    }
  }

  // If no imports return original string of lines
  if (noImports()) {
    var joinedLines = lines.join('\n');
    if (joinedLines.endsWith('\n') && !joinedLines.endsWith('\n\n')) {
      joinedLines += '\n';
    } else if (!joinedLines.endsWith('\n')) {
      joinedLines += '\n';
    }

    return ImportSortData(joinedLines, false);
  }

  // Remove spaces
  if (beforeImportLines.isNotEmpty) {
    if (beforeImportLines.last.trim() == '') {
      beforeImportLines.removeLast();
    }
  }

  final sortedLines = <String>[...beforeImportLines];

  // Adding content conditionally
  if (beforeImportLines.isNotEmpty) {
    sortedLines.add('');
  }
  if (dartImports.isNotEmpty) {
    dartImports.sort();
    sortedLines.addAll(dartImports);
  }
  if (flutterImports.isNotEmpty) {
    if (dartImports.isNotEmpty) sortedLines.add('');
    flutterImports.sort();
    sortedLines.addAll(flutterImports);
  }
  if (packageImports.isNotEmpty) {
    if (dartImports.isNotEmpty || flutterImports.isNotEmpty) {
      sortedLines.add('');
    }
    packageImports.sort();
    sortedLines.addAll(packageImports);
  }

  if (projectImports.isNotEmpty || projectRelativeImports.isNotEmpty) {
    if (dartImports.isNotEmpty ||
        flutterImports.isNotEmpty ||
        packageImports.isNotEmpty) {
      sortedLines.add('');
    }

    sortedLines.addAll([...projectImports, ...projectRelativeImports]..sort());
  }

  sortedLines.add('');

  var addedCode = false;
  for (var j = 0; j < afterImportLines.length; j++) {
    if (afterImportLines[j] != '') {
      sortedLines.add(afterImportLines[j]);
      addedCode = true;
    }
    if (addedCode && afterImportLines[j] == '') {
      sortedLines.add(afterImportLines[j]);
    }
  }
  sortedLines.add('');

  final sortedFile = sortedLines.join('\n');
  final original = '${lines.join('\n')}\n';

  if (original == sortedFile) {
    return ImportSortData(original, false);
  }

  return ImportSortData(sortedFile, true);
}

/// Get the number of times a string contains another
/// string
int _timesContained(String string, String looking) =>
    string.split(looking).length - 1;

/// Data to return from a sort
class ImportSortData {
  final String sortedFile;
  final bool updated;

  const ImportSortData(this.sortedFile, this.updated);
}
