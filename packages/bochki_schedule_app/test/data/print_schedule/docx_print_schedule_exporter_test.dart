import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bochki_schedule_app/src/data/print_schedule/docx_print_schedule_exporter.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports docx with expected file name and content', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_docx_export_test');
    addTearDown(() => tempDirectory.delete(recursive: true));

    final exporter = DocxPrintScheduleExporter(
      safeFileWriter: const AtomicFileWriter(),
    );
    final file = await exporter.export(
      document: PrintScheduleDocument(
        workday: Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
        groupBy: PrintScheduleGroupBy.byNames,
        title: 'Дата расписания 17.07.2026',
        textBefore: 'До таблицы',
        rows: const [
          PrintScheduleRow(
            participantName: 'Иванов Иван',
            startTime: '09:00',
            procedureName: 'Бочка',
            assistantName: '',
          ),
        ],
        textAfter: 'После таблицы',
      ),
      outputDirectory: tempDirectory,
    );

    expect(file.path, endsWith('raspechatka-17.07.2026-po-familiyam.docx'));

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final names = archive.files.map((entry) => entry.name).toList();
    expect(names, contains('[Content_Types].xml'));
    expect(names, contains('word/document.xml'));

    final documentXml = archive.files
        .firstWhere((entry) => entry.name == 'word/document.xml')
        .content as List<int>;
    final documentXmlString = utf8.decode(documentXml);
    expect(documentXmlString, contains('Дата расписания 17.07.2026'));
    expect(documentXmlString, contains('Участник'));
    expect(documentXmlString, contains('Иванов Иван'));
    expect(documentXmlString, contains('После таблицы'));
  });
}
