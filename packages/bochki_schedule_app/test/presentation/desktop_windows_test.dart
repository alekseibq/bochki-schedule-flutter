import 'package:bochki_schedule_app/src/presentation/desktop_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windowKindFromArguments', () {
    test('reads a statistics window argument', () {
      expect(
        windowKindFromArguments('{"kind":"procedureStatistics"}'),
        DesktopWindowKind.procedureStatistics,
      );
    });

    test('reads directory and editor window arguments', () {
      expect(
        windowKindFromArguments('{"kind":"participants"}'),
        DesktopWindowKind.participants,
      );
      expect(
        windowKindFromArguments('{"kind":"procedureKindEditor"}'),
        DesktopWindowKind.procedureKindEditor,
      );
    });

    test('treats invalid arguments as the main window', () {
      expect(windowKindFromArguments('invalid'), DesktopWindowKind.main);
    });
  });
}
