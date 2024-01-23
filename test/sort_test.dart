import 'package:reimport_please/src.dart';
import 'package:test/test.dart';

void main() {
  test('sortImports', () {
    final sorted = sortImports(
      [
        'import \'package:example/b.dart\';',
        'import \'package:example/a.dart\';',
        'import \'package:example/src/implementation.dart\';',
        'import \'package:example/src/wow.dart\';',
        'import \'package:collection/collection.dart\';',
        'import \'dart:js\';',
        'import \'relative_file.dart\';',
      ],
      'example',
    ).sortedFile;

    expect(sorted, '''import 'dart:js';

import 'package:collection/collection.dart';

import '/a.dart';
import '/b.dart';
import '/src/implementation.dart';
import '/src/wow.dart';
import 'relative_file.dart';

''');
  });
}
