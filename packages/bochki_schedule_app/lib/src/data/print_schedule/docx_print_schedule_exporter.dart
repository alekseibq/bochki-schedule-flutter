import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bochki_schedule_infra/bochki_schedule_infra.dart';

import '../../domain/print_schedule/print_schedule_document.dart';
import '../../domain/print_schedule/print_schedule_exporter.dart';

final class DocxPrintScheduleExporter implements PrintScheduleExporter {
  DocxPrintScheduleExporter({
    required SafeFileWriter safeFileWriter,
  }) : _safeFileWriter = safeFileWriter;

  final SafeFileWriter _safeFileWriter;

  @override
  Future<File> export({
    required PrintScheduleDocument document,
    required Directory outputDirectory,
  }) async {
    final file = File(
      '${outputDirectory.path}/${_buildFileName(document)}',
    );
    final archive = Archive();

    _addTextFile(archive, '[Content_Types].xml', _contentTypesXml);
    _addTextFile(archive, '_rels/.rels', _rootRelsXml);
    _addTextFile(archive, 'docProps/app.xml', _appXml);
    _addTextFile(archive, 'docProps/core.xml', _coreXml);
    _addTextFile(archive, 'word/document.xml', _buildDocumentXml(document));
    _addTextFile(archive, 'word/styles.xml', _stylesXml);
    _addTextFile(
      archive,
      'word/_rels/document.xml.rels',
      _documentRelsXml,
    );

    final bytes = ZipEncoder().encode(archive);
    await _safeFileWriter.writeBytes(file, bytes);
    return file;
  }

  void _addTextFile(Archive archive, String name, String contents) {
    final bytes = utf8.encode(contents);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _buildFileName(PrintScheduleDocument document) {
    final date = _formatDate(document.workday.calendarDate);
    return 'raspechatka-$date-${document.groupBy.fileSlug}.docx';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }

  String _buildDocumentXml(PrintScheduleDocument document) {
    final sections = <String>[
      _paragraphXml(
        document.title,
        fontSize: 36,
        alignment: 'center',
      ),
    ];
    sections.addAll(_textBeforeParagraphsXml(document.textBefore));
    sections.add(_tableXml(document));
    sections.addAll(_textAfterParagraphsXml(document.textAfter));
    sections.add(_sectionPropertiesXml);

    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
 xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
 xmlns:v="urn:schemas-microsoft-com:vml"
 xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:w10="urn:schemas-microsoft-com:office:word"
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
 xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
 xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
 xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
 xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
 mc:Ignorable="w14 wp14">
  <w:body>
    ${sections.join('\n    ')}
  </w:body>
</w:document>
''';
  }

  List<String> _textBeforeParagraphsXml(String text) {
    if (text.trim().isEmpty) {
      return const [];
    }
    return [
      for (final line in text.split('\n'))
        _paragraphXml(line, fontSize: 34, spacingAfter: 360),
    ];
  }

  List<String> _textAfterParagraphsXml(String text) {
    if (text.trim().isEmpty) {
      return const [];
    }
    return [
      for (final line in text.split('\n'))
        _paragraphXml(line, fontSize: 34, spacingBefore: 360),
    ];
  }

  String _paragraphXml(
    String text, {
    required int fontSize,
    String? alignment,
    int? spacingBefore,
    int? spacingAfter,
  }) {
    final properties = <String>[];
    if (alignment != null) {
      properties.add('<w:jc w:val="$alignment"/>');
    }
    if (spacingBefore != null || spacingAfter != null) {
      final before = spacingBefore == null ? '' : ' w:before="$spacingBefore"';
      final after = spacingAfter == null ? '' : ' w:after="$spacingAfter"';
      properties.add('<w:spacing$before$after/>');
    }
    final paragraphProperties = properties.isEmpty
        ? ''
        : '<w:pPr>${properties.join()}</w:pPr>';
    return '<w:p>'
        '$paragraphProperties${_runXml(text, fontSize: fontSize)}</w:p>';
  }

  String _runXml(String text, {required int fontSize}) {
    return '''
<w:r>
  <w:rPr>
    <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
    <w:b/>
    <w:sz w:val="$fontSize"/>
    <w:szCs w:val="$fontSize"/>
  </w:rPr>
  <w:t xml:space="preserve">${_escapeXml(text)}</w:t>
</w:r>''';
  }

  String _tableXml(PrintScheduleDocument document) {
    final rows = <String>[
      _tableRowXml(
        const ['Участник', 'Время', 'Процедура', 'Ассистент'],
        isHeader: true,
      ),
      for (final row in document.rows)
        _tableRowXml([
          row.participantName,
          _formatTimeRange(row.startTime, row.finishTime),
          row.procedureName,
          row.assistantName,
        ]),
    ];
    return '''
<w:tbl>
  <w:tblPr>
    <w:tblStyle w:val="TableGrid"/>
    <w:tblInd w:w="108" w:type="dxa"/>
    <w:tblW w:w="10897" w:type="dxa"/>
    <w:tblCellMar>
      <w:left w:w="108" w:type="dxa"/>
      <w:right w:w="108" w:type="dxa"/>
    </w:tblCellMar>
    <w:tblLayout w:type="fixed"/>
  </w:tblPr>
  <w:tblGrid>
    <w:gridCol w:w="3067"/>
    <w:gridCol w:w="2160"/>
    <w:gridCol w:w="2610"/>
    <w:gridCol w:w="3060"/>
  </w:tblGrid>
  ${rows.join('\n  ')}
</w:tbl>
''';
  }

  String _tableRowXml(List<String> cells, {bool isHeader = false}) {
    final cellsXml = [
      for (var index = 0; index < cells.length; index++)
        _tableCellXml(cells[index], isHeader, _columnWidths[index]),
    ].join();
    return '<w:tr><w:trPr><w:cantSplit/></w:trPr>$cellsXml</w:tr>';
  }

  String _tableCellXml(String text, bool isHeader, int width) {
    final paragraph = _paragraphXml(
      text,
      fontSize: 34,
      alignment: isHeader ? 'center' : null,
    );
    return '''
<w:tc>
  <w:tcPr>
    <w:tcW w:w="$width" w:type="dxa"/>
    ${isHeader ? '<w:vAlign w:val="center"/>' : ''}
  </w:tcPr>
  $paragraph
</w:tc>
''';
  }

  static const List<int> _columnWidths = [3067, 2160, 2610, 3060];

  String _formatTimeRange(String startTime, String? finishTime) {
    if (finishTime == null || finishTime.isEmpty) {
      return startTime;
    }
    return '$startTime - $finishTime';
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

const String _contentTypesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
''';

const String _rootRelsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
''';

const String _documentRelsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
''';

const String _stylesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="table" w:styleId="TableGrid">
    <w:name w:val="Table Grid"/>
    <w:tblPr>
      <w:tblBorders>
        <w:top w:val="single" w:color="auto" w:sz="4" w:space="0"/>
        <w:left w:val="single" w:color="auto" w:sz="4" w:space="0"/>
        <w:bottom w:val="single" w:color="auto" w:sz="4" w:space="0"/>
        <w:right w:val="single" w:color="auto" w:sz="4" w:space="0"/>
        <w:insideH w:val="single" w:color="auto" w:sz="4" w:space="0"/>
        <w:insideV w:val="single" w:color="auto" w:sz="4" w:space="0"/>
      </w:tblBorders>
    </w:tblPr>
  </w:style>
</w:styles>
''';

const String _coreXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Bochki Schedule Print</dc:title>
  <dc:creator>Bochki Schedule</dc:creator>
</cp:coreProperties>
''';

const String _appXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Bochki Schedule</Application>
</Properties>
''';

const String _sectionPropertiesXml = '''
<w:sectPr>
  <w:pgSz w:w="12240" w:h="15840"/>
  <w:pgMar w:top="1138" w:right="720" w:bottom="1138" w:left="720" w:header="720" w:footer="720" w:gutter="0"/>
  <w:cols w:space="720"/>
  <w:docGrid w:linePitch="360"/>
</w:sectPr>
''';
