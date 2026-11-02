import 'package:bochki_schedule_app/src/features/participants/ipc_participants_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create returns the persisted participant identity and normalized name',
      () async {
    final operations = IpcParticipantsOperations((method, arguments) async {
      expect(method, 'directoryMutate');
      return {
        'ok': true,
        'entry': {'id': '42', 'name': 'Анна'}
      };
    });
    final participant = await operations.create(' Анна ');
    expect(participant.id, '42');
    expect(participant.name, 'Анна');
  });
}
