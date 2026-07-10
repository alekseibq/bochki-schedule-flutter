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
    expect(document.humans, isEmpty);
    expect(document.procedureKinds, isEmpty);
  });

  test('project document serializes and deserializes predictably', () {
    final document = ProjectDocument(
      schemaVersion: 1,
      nextId: 7,
      humans: const [
        <String, Object?>{
          'id': 1,
          'name': 'Assistant One',
          'isParticipant': false,
          'isAssistant': true,
          'deleted': false,
        },
        <String, Object?>{
          'id': 2,
          'name': 'Participant One',
          'isParticipant': true,
          'isAssistant': false,
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
    expect(restored.humans.first['name'], 'Assistant One');
    expect(restored.humans.last['name'], 'Participant One');
    expect(restored.humans.last['deleted'], isTrue);
    expect(restored.procedureKinds.single['name'], 'Procedure One');
  });

  test('project document migrates legacy participants and trainers into humans',
      () {
    final restored = ProjectDocument.fromJson(const <String, Object?>{
      'schemaVersion': 1,
      'nextId': 3,
      'participants': <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Participant Name'},
        <String, Object?>{'id': 2, 'name': 'Shared Person'},
      ],
      'trainers': <Map<String, Object?>>[
        <String, Object?>{'id': 2, 'name': 'Assistant Name'},
        <String, Object?>{'id': 3, 'name': 'Assistant One'},
      ],
    });

    expect(restored.humans, [
      <String, Object?>{
        'id': 3,
        'name': 'Assistant One',
        'isParticipant': false,
        'isAssistant': true,
        'deleted': false,
      },
      <String, Object?>{
        'id': 1,
        'name': 'Participant Name',
        'isParticipant': true,
        'isAssistant': false,
        'deleted': false,
      },
      <String, Object?>{
        'id': 2,
        'name': 'Shared Person',
        'isParticipant': true,
        'isAssistant': true,
        'deleted': false,
      },
    ]);
    expect(restored.toJson().containsKey('trainers'), isFalse);
    expect(restored.toJson().containsKey('participants'), isFalse);
    expect(restored.toJson()['humans'], restored.humans);
  });
}
