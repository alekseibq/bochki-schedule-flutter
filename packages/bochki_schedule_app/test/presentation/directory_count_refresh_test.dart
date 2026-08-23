import 'package:bochki_schedule_app/src/presentation/shell/bochki_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes only the count for the changed directory', () async {
    final refreshed = <String>[];

    Future<void> record(String directory) async {
      refreshed.add(directory);
    }

    for (final directory in const [
      'participants',
      'assistants',
      'procedureKinds',
      'workdays',
    ]) {
      await refreshDirectoryCount(
        directory,
        refreshParticipants: () => record('participants'),
        refreshAssistants: () => record('assistants'),
        refreshProcedureKinds: () => record('procedureKinds'),
        refreshWorkdays: () => record('workdays'),
      );
    }

    expect(
      refreshed,
      ['participants', 'assistants', 'procedureKinds', 'workdays'],
    );
  });

  test('ignores an unknown directory', () async {
    var refreshCount = 0;

    await refreshDirectoryCount(
      'unknown',
      refreshParticipants: () async {
        refreshCount++;
      },
      refreshAssistants: () async {
        refreshCount++;
      },
      refreshProcedureKinds: () async {
        refreshCount++;
      },
      refreshWorkdays: () async {
        refreshCount++;
      },
    );

    expect(refreshCount, 0);
  });
}
