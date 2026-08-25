import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bochki_schedule_app/src/data/print_schedule/docx_print_schedule_exporter.dart';
import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports DOCX using the approved print layout', () async {
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
        textBefore: 'До таблицы\n\nВторая строка',
        rows: const [
          PrintScheduleRow(
            participantName: 'Иванов Иван',
            startTime: '09:00',
            finishTime: '10:30',
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
    expect(documentXmlString, contains('09:00 - 10:30'));
    expect(documentXmlString, contains('После таблицы'));
    expect(
      documentXmlString,
      contains('<w:pgSz w:w="12240" w:h="15840"/>'),
    );
    expect(
      documentXmlString,
      contains(
        '<w:pgMar w:top="1138" w:right="720" w:bottom="1138" w:left="720"',
      ),
    );
    expect(documentXmlString, contains('<w:tblStyle w:val="TableGrid"/>'));
    expect(documentXmlString, contains('<w:tblW w:w="10897" w:type="dxa"/>'));
    expect(documentXmlString, contains('<w:gridCol w:w="3067"/>'));
    expect(documentXmlString, contains('<w:gridCol w:w="2160"/>'));
    expect(documentXmlString, contains('<w:gridCol w:w="2610"/>'));
    expect(documentXmlString, contains('<w:gridCol w:w="3060"/>'));
    expect(documentXmlString, contains('<w:cantSplit/>'));
    expect(documentXmlString, isNot(contains('<w:tblHeader/>')));
    expect(documentXmlString, contains('<w:jc w:val="center"/>'));
    expect(documentXmlString, contains('<w:sz w:val="36"/>'));
    expect(documentXmlString, contains('<w:sz w:val="34"/>'));
    expect(documentXmlString, contains('<w:rFonts w:ascii="Calibri"'));

    final firstTextIndex = documentXmlString.indexOf('До таблицы');
    final secondTextIndex = documentXmlString.indexOf('Вторая строка');
    expect(firstTextIndex, greaterThanOrEqualTo(0));
    expect(secondTextIndex, greaterThan(firstTextIndex));
    expect(
      documentXmlString.substring(firstTextIndex, secondTextIndex),
      isNot(contains('<w:br/>')),
    );
  });

  test('exports only the start time when the finish time is unknown', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_docx_export_test');
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = await DocxPrintScheduleExporter(
      safeFileWriter: const AtomicFileWriter(),
    ).export(
      document: PrintScheduleDocument(
        workday: Workday(
          id: '1',
          name: 'Пятница',
          calendarDate: DateTime(2026, 7, 17),
        ),
        groupBy: PrintScheduleGroupBy.byTime,
        title: 'Дата расписания 17.07.2026',
        textBefore: '',
        rows: const [
          PrintScheduleRow(
            participantName: 'Иванов Иван',
            startTime: '09:00',
            finishTime: null,
            procedureName: 'Не найдено',
            assistantName: '',
          ),
        ],
        textAfter: '',
      ),
      outputDirectory: tempDirectory,
    );

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final documentXml = archive.files
        .firstWhere((entry) => entry.name == 'word/document.xml')
        .content as List<int>;
    expect(utf8.decode(documentXml), contains('>09:00</w:t>'));
  });
}
