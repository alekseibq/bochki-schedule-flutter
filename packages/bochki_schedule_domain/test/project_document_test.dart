import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:test/test.dart';

void main() {
  test('defaults program settings when field is absent', () {
    final document = ProjectDocument.fromJson(
      <String, Object?>{
        'schemaVersion': 1,
        'nextId': 1,
      },
    );

    expect(document.programSettings, ProgramSettings.defaults);
    expect(document.printPresetParams, PrintPresetParams.defaults);
  });

  test('throws when stored program settings are incomplete', () {
    expect(
      () => ProjectDocument.fromJson(
        <String, Object?>{
          'programSettings': <String, Object?>{
            'lunchStart': <String, Object?>{'hour': 14, 'minute': 0},
          },
        },
      ),
      throwsFormatException,
    );
  });

  test('serializes program settings into project document json', () {
    const settings = ProgramSettings(
      lunchStart: ProgramSettingsTime(hour: 12, minute: 0),
      lunchEnd: ProgramSettingsTime(hour: 13, minute: 0),
      minimumHour: 8,
      maximumHour: 18,
    );

    final json = const ProjectDocument(programSettings: settings).toJson();

    expect(json['programSettings'], settings.toJson());
  });

  test('throws when stored print preset params are incomplete', () {
    expect(
      () => ProjectDocument.fromJson(
        <String, Object?>{
          'printPresetParams': <String, Object?>{
            'workdayId': '1',
            'textBefore': '',
          },
        },
      ),
      throwsFormatException,
    );
  });

  test('serializes print preset params into project document json', () {
    const params = PrintPresetParams(
      workdayId: '2',
      textBefore: 'Начало',
      textAfter: 'Конец',
    );

    final json = const ProjectDocument(printPresetParams: params).toJson();

    expect(json['printPresetParams'], params.toJson());
  });
}
