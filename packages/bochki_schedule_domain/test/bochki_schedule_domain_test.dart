import 'package:bochki_schedule_domain/bochki_schedule_domain.dart';
import 'package:test/test.dart';

void main() {
  test('package exports compile', () {
    expect(bochkiScheduleDomainPackageName, 'bochki_schedule_domain');
  });

  test('sequential id generator increments by one', () {
    final generator = SequentialIdGenerator();

    expect(generator.nextId(), 1);
    expect(generator.nextId(), 2);
    expect(generator.nextId(), 3);
  });

  test('sequential id generator respects custom start value', () {
    final generator = SequentialIdGenerator(startAt: 41);

    expect(generator.nextId(), 41);
    expect(generator.nextId(), 42);
  });

  test('project document uses current schema version by default', () {
    final document = ProjectDocument.initial();

    expect(document.schemaVersion, SchemaVersion.current);
    expect(document.nextId, 1);
    expect(document.assistants, isEmpty);
    expect(document.participants, isEmpty);
    expect(document.procedureKinds, isEmpty);
  });

  test('project document serializes and deserializes predictably', () {
    final document = ProjectDocument(
      schemaVersion: 1,
      nextId: 7,
      assistants: const [
        <String, Object?>{'id': 1, 'name': 'Assistant One'},
      ],
      participants: const [
        <String, Object?>{
          'id': 2,
          'name': 'Participant One',
          'deleted': true,
        },
      ],
      procedureKinds: const [
        <String, Object?>{
          'id': 3,
          'patternId': 'curated',
          'name': 'Procedure One',
          'capacity': 5,
          'participantBusyTime': 30,
        },
      ],
    );

    final json = document.toJson();
    final restored = ProjectDocument.fromJson(json);

    expect(json['schemaVersion'], 1);
    expect(json['nextId'], 7);
    expect(restored.schemaVersion, 1);
    expect(restored.nextId, 7);
    expect(restored.assistants.single['name'], 'Assistant One');
    expect(restored.participants.single['name'], 'Participant One');
    expect(restored.participants.single['deleted'], isTrue);
    expect(restored.procedureKinds.single['name'], 'Procedure One');
  });

  test('project document reads legacy trainers collection as assistants', () {
    final restored = ProjectDocument.fromJson(const <String, Object?>{
      'schemaVersion': 1,
      'nextId': 3,
      'trainers': <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Assistant One'},
      ],
    });

    expect(restored.assistants.single['name'], 'Assistant One');
    expect(restored.toJson().containsKey('trainers'), isFalse);
    expect(restored.toJson()['assistants'], [
      <String, Object?>{'id': 1, 'name': 'Assistant One'},
    ]);
  });
}
