import 'package:bochki_schedule_app/src/features/participants/ipc_participants_operations.dart';
import 'package:bochki_schedule_app/src/domain/participants/participants_validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validation failures retain the participant-specific message', () async {
    final operations = IpcParticipantsOperations((_, __) async =>
        {'ok': false, 'validation': true, 'error': 'Имя занято'});
    await expectLater(
      operations.create('Имя'),
      throwsA(isA<ParticipantsValidationException>()
          .having((error) => error.message, 'message', 'Имя занято')),
    );
  });
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
