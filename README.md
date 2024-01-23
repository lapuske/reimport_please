`reimport_please`
=================

`reimport_please` is a package aimed to help maintain consistency with imports. The package only resorts the packages and refactors the `package:your_package` imports to relative ones. It follows the following pattern:

```dart
// First the `dart` imports.
import 'dart:core';
import 'dart:math';

// Then the packages imports.
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

// Finally, the relative imports.
import '/a.dart';
import '/b.dart';
import '/src/dir/yes.dart';
import 'src/impl.dart';
```




## Usage


### Sorting

1. Add the package to your development dependencies:

```yaml
dev_dependencies:
  reimport_please:
    git: https://github.com/lapuske/reimport_please
```

2. Run the `dart run`:

```bash
dart run reimport_please
```

3. You're all done.


### Dry-run

```bash
dart run reimport_please --dry-run
```

Will exit with `1`, if any files are to be changed. Otherwise exists with `0` (success).
