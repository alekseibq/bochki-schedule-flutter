import 'dart:io';

import 'package:bochki_schedule_app/src/presentation/startup_error_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('describes a file system startup error with its path', () {
    final description = describeStartupError(
      const FileSystemException('Operation not permitted', '/Applications'),
    );

    expect(description, contains('Не удалось получить доступ'));
    expect(description, contains('/Applications'));
    expect(description, contains('Operation not permitted'));
  });

  test('describes a malformed project document', () {
    final description = describeStartupError(
      const FormatException('Unexpected character'),
    );

    expect(description, contains('project.json'));
    expect(description, contains('Unexpected character'));
  });
}
