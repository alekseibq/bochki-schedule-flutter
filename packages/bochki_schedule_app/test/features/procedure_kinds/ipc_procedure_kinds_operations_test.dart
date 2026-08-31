import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IpcProcedureKindsOperations', () {
    late List<({String method, Object? arguments})> calls;
    late IpcProcedureKindsOperations operations;

    setUp(() {
      calls = [];
      operations = IpcProcedureKindsOperations((method, arguments) async {
        calls.add((method: method, arguments: arguments));
        return switch (method) {
          'directorySnapshot' => {
              'entries': [
                {
                  'id': 'kind-1',
                  'patternId': 'curated',
                  'name': 'Бочка',
                  'shortName': 'Бочка',
                  'capacity': 2,
                  'participantBusyTime': 30,
                  'assistantBusyTime': 10,
                  'resourceBusyTime': 15,
                },
              ],
            },
          'directoryReferences' => 3,
          'directoryMutate' => {'ok': true},
          _ => throw StateError('Unexpected method: $method'),
        };
      });
    });

    test('lists and decodes procedure kinds', () async {
      final kinds = await operations.list();

      expect(kinds.single.name, 'Бочка');
      expect(kinds.single.assistantBusyTime, 10);
      expect(calls.single,
          (method: 'directorySnapshot', arguments: 'procedureKinds'));
    });

    test('sends the typed create and update payloads', () async {
      final kind = ProcedureKind(
        id: 'kind-1',
        patternId: 'curated',
        name: 'Бочка',
        capacity: 2,
        participantBusyTime: 30,
        assistantBusyTime: 10,
        resourceBusyTime: 15,
      );

      await operations.create(kind);
      await operations.update(kind);

      expect((calls[0].arguments as Map)['entry']['assistantBusyTime'], 10);
      expect((calls[1].arguments as Map)['id'], 'kind-1');
    });

    test('counts references and deletes with only the ID', () async {
      expect(await operations.countReferences('kind-1'), 3);
      await operations.delete('kind-1');

      final delete = calls.last.arguments as Map;
      expect(delete['directory'], 'procedureKinds');
      expect(delete['action'], 'delete');
      expect(delete['id'], 'kind-1');
      expect(delete['entry'], isEmpty);
    });
  });
}
