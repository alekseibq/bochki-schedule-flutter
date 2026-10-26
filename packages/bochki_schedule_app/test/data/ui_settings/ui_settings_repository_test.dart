import 'dart:async';
import 'dart:io';

import 'package:bochki_schedule_app/src/data/ui_settings/ui_settings_repository.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips procedure kinds column widths', () {
    const settings = UiSettings(
      procedureKindsColumnWidths: [36, 140, 80, 50, 50, 50, 50, 60, 60],
    );

    final restored = UiSettings.fromJson(settings.toJson());

    expect(restored.procedureKindsColumnWidths,
        settings.procedureKindsColumnWidths);
  });

  test('uses an empty procedure kinds widths list for old settings', () {
    final restored = UiSettings.fromJson({'uiScale': 1.1});

    expect(restored.procedureKindsColumnWidths, isEmpty);
  });

  test('round-trips quick reassignments column widths', () {
    const settings = UiSettings(
      quickReassignmentsColumnWidths: [100, 240, 300, 300],
    );

    final restored = UiSettings.fromJson(settings.toJson());

    expect(
      restored.quickReassignmentsColumnWidths,
      settings.quickReassignmentsColumnWidths,
    );
  });

  test('uses empty quick reassignments widths for old settings', () {
    final restored = UiSettings.fromJson({'uiScale': 1.1});

    expect(restored.quickReassignmentsColumnWidths, isEmpty);
  });

  test('round-trips workdays column widths', () {
    const settings = UiSettings(
      workdaysColumnWidths: [260, 160, 100, 90],
    );

    final restored = UiSettings.fromJson(settings.toJson());

    expect(restored.workdaysColumnWidths, settings.workdaysColumnWidths);
  });

  test('uses empty workdays widths for old settings', () {
    final restored = UiSettings.fromJson({'uiScale': 1.1});

    expect(restored.workdaysColumnWidths, isEmpty);
  });

  test('serializes debounced updates and flushes the latest snapshot',
      () async {
    final writer = _ControlledWriter();
    final repository = UiSettingsRepository(
      file: File('ui_settings.json'),
      writer: writer,
    );

    unawaited(repository.update(const UiSettings(uiScale: 1.2)));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(writer.contents, hasLength(1));

    unawaited(repository.update(const UiSettings(uiScale: 1.3)));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(writer.contents, hasLength(1));

    writer.completeFirst();
    await repository.flush();

    expect(writer.contents, hasLength(2));
    expect(writer.contents.last, contains('1.3'));
  });
}

final class _ControlledWriter implements SafeFileWriter {
  final _firstWrite = Completer<void>();
  final contents = <String>[];

  @override
  Future<void> writeString(File destination, String value) {
    contents.add(value);
    return contents.length == 1 ? _firstWrite.future : Future<void>.value();
  }

  @override
  Future<void> writeBytes(File destination, List<int> contents) =>
      Future<void>.value();

  void completeFirst() => _firstWrite.complete();
}
