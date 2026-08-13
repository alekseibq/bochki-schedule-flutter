import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bochki_schedule_app/src/data/procedure_statistics/docx_procedure_statistics_exporter.dart';
import 'package:bochki_schedule_app/src/domain/procedure_statistics/procedure_statistics_document.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports statistics cells as DOCX XML rather than escaped text',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('bochki_statistics_docx_test');
    addTearDown(() => tempDirectory.delete(recursive: true));
    final exporter = DocxProcedureStatisticsExporter(
      safeFileWriter: const AtomicFileWriter(),
    );

    final file = await exporter.export(
      document: const ProcedureStatisticsDocument(
        fileName: 'statistika-po-soprovozhdeniyam-2026-07-13-2026-07-14.docx',
        pages: [
          ProcedureStatisticsPage(
            workdays: [],
            rows: [
              ProcedureStatisticsRow(
                name: 'Иванов & Иван',
                cells: [
                  ProcedureStatisticsCell([
                    ProcedureStatisticsTextLine('1 Бег'),
                    ProcedureStatisticsTextLine('Бочка - Анна'),
                    ProcedureStatisticsDividerLine(),
                    ProcedureStatisticsTextLine('Группа 2+'),
                  ]),
                  ProcedureStatisticsCell([]),
                ],
              ),
            ],
          ),
        ],
      ),
      outputDirectory: tempDirectory,
    );

    expect(
      file.path,
      endsWith('statistika-po-soprovozhdeniyam-2026-07-13-2026-07-14.docx'),
    );

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final documentXml = archive.files
        .firstWhere((entry) => entry.name == 'word/document.xml')
        .content as List<int>;
    final xml = utf8.decode(documentXml);

    expect(xml, contains('<w:t xml:space="preserve">1 Бег</w:t>'));
    expect(xml, contains('<w:t xml:space="preserve">Бочка - Анна</w:t>'));
    expect(xml, contains('<w:pBdr><w:bottom w:val="single" w:sz="8"/>'));
    expect(xml, contains('Иванов &amp; Иван'));
    expect(xml, isNot(contains('&lt;w:tc&gt;')));
    expect(xml, isNot(contains('&lt;/w:tc&gt;')));
  });
}
