import 'package:bochki_schedule_app/src/data/ui_settings/ui_settings_repository.dart';
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
}
