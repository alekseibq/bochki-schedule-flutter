import 'package:bochki_schedule_app/src/features/assistants/ipc_assistants_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create returns the persisted assistant identity and normalized name',
      () async {
    final operations = IpcAssistantsOperations((method, arguments) async {
      expect(method, 'directoryMutate');
      return {
        'ok': true,
        'entry': {'id': '43', 'name': 'Ирина', 'shortName': 'Ир.'}
      };
    });
    final assistant = await operations.create(' Ирина ');
    expect(assistant.id, '43');
    expect(assistant.name, 'Ирина');
    expect(assistant.shortName, 'Ир.');
  });
}
