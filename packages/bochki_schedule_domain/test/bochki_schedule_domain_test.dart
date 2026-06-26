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
    expect(document.trainers, isEmpty);
    expect(document.participants, isEmpty);
  });

  test('project document serializes and deserializes predictably', () {
    final document = ProjectDocument(
      schemaVersion: 1,
      nextId: 7,
      trainers: const [
        <String, Object?>{'id': 1, 'name': 'Trainer One'},
      ],
      participants: const [
        <String, Object?>{
          'id': 2,
          'name': 'Participant One',
          'deleted': true,
        },
      ],
    );

    final json = document.toJson();
    final restored = ProjectDocument.fromJson(json);

    expect(json['schemaVersion'], 1);
    expect(json['nextId'], 7);
    expect(restored.schemaVersion, 1);
    expect(restored.nextId, 7);
    expect(restored.trainers.single['name'], 'Trainer One');
    expect(restored.participants.single['name'], 'Participant One');
    expect(restored.participants.single['deleted'], isTrue);
  });
}
