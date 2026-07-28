import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import '../../domain/procedure_statistics/procedure_statistics_document.dart';
import '../../domain/procedure_statistics/procedure_statistics_exporter.dart';

final class DocxProcedureStatisticsExporter
    implements ProcedureStatisticsExporter {
  DocxProcedureStatisticsExporter({required SafeFileWriter safeFileWriter})
      : _safeFileWriter = safeFileWriter;
  final SafeFileWriter _safeFileWriter;

  @override
  Future<File> export(
      {required ProcedureStatisticsDocument document,
      required Directory outputDirectory}) async {
    final archive = Archive();
    _add(archive, '[Content_Types].xml', _contentTypes);
    _add(archive, '_rels/.rels', _rootRels);
    _add(archive, 'word/_rels/document.xml.rels', _documentRels);
    _add(archive, 'word/document.xml', _document(document));
    final file = File('${outputDirectory.path}/${document.fileName}');
    await _safeFileWriter.writeBytes(file, ZipEncoder().encode(archive));
    return file;
  }

  void _add(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _document(ProcedureStatisticsDocument document) =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${[
        for (var i = 0; i < document.pages.length; i++)
          '${_table(document.pages[i])}${i + 1 < document.pages.length ? '<w:p><w:r><w:br w:type="page"/></w:r></w:p>' : ''}'
      ].join()}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr></w:body></w:document>''';
  String _table(ProcedureStatisticsPage page) =>
      '<w:tbl><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="8"/><w:left w:val="single" w:sz="8"/><w:bottom w:val="single" w:sz="8"/><w:right w:val="single" w:sz="8"/><w:insideH w:val="single" w:sz="8"/><w:insideV w:val="single" w:sz="8"/></w:tblBorders></w:tblPr><w:tblGrid><w:gridCol w:w="2400"/><w:gridCol w:w="2300"/><w:gridCol w:w="2300"/><w:gridCol w:w="2300"/><w:gridCol w:w="2300"/></w:tblGrid>${_row([
            'Кто',
            ...page.workdays.map((day) => day?.name ?? '')
          ], header: true)}${page.rows.map((row) => row.cells.isEmpty ? _row([
              row.name,
              '',
              '',
              '',
              ''
            ], header: true) : _row([
              row.name,
              ...row.cells.map(_cell)
            ])).join()}</w:tbl>';
  String _row(List<String> values, {bool header = false}) =>
      '<w:tr>${values.map((value) => _cellText(value, bold: header)).join()}</w:tr>';
  String _cell(ProcedureStatisticsCell cell) =>
      '<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/></w:tcPr>${cell.lines.isEmpty ? _paragraph('') : cell.lines.map((line) => switch (line) {
            ProcedureStatisticsTextLine(:final text) => _paragraph(text),
            ProcedureStatisticsDividerLine() =>
              '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="8"/></w:pBdr></w:pPr></w:p>',
            _ => _paragraph(''),
          }).join()}</w:tc>';
  String _cellText(String value, {bool bold = false}) =>
      '<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/></w:tcPr>${_paragraph(value, bold: bold)}</w:tc>';
  String _paragraph(String value, {bool bold = false}) =>
      '<w:p><w:r>${bold ? '<w:rPr><w:b/></w:rPr>' : ''}<w:t xml:space="preserve">${_escape(value)}</w:t></w:r></w:p>';
  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypes =
    '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''';
const _rootRels =
    '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''';
const _documentRels =
    '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';
