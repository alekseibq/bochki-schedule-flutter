import 'package:bochki_schedule_app/src/app_launch_arguments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses app data override from equals form', () {
    final directory = resolveAppDataDirectoryOverride([
      '--app-data-dir=/tmp/bochki_schedule_test',
    ]);

    expect(directory?.path, '/tmp/bochki_schedule_test');
  });

  test('parses app data override from split form', () {
    final directory = resolveAppDataDirectoryOverride([
      '--app-data-dir',
      '/tmp/bochki_schedule_test',
    ]);

    expect(directory?.path, '/tmp/bochki_schedule_test');
  });

  test('ignores unrelated arguments', () {
    final directory = resolveAppDataDirectoryOverride([
      '--foo=bar',
      '--dart-define=BAZ=1',
    ]);

    expect(directory, isNull);
  });
}
