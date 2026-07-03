import 'package:bochki_schedule_app/bochki_schedule_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('participants use cases', () {
    test('list loads sorted participants', () async {
      final repository = _InMemoryParticipantsRepository(
        participants: [
          Participant(id: '2', name: 'Вася'),
          Participant(id: '1', name: 'Анна'),
        ],
      );
      final useCase = ListParticipantsUseCase(repository);

      final participants = await useCase.execute();

      expect(participants.map((participant) => participant.name), [
        'Анна',
        'Вася',
      ]);
    });

    test('create adds normalized participant', () async {
      final repository = _InMemoryParticipantsRepository();
      final useCase = CreateParticipantUseCase(repository);

      final participant = await useCase.execute('  Иван   Иванов  ');

      expect(participant.id, '1');
      expect(participant.name, 'Иван Иванов');
      expect(repository.participants.single.name, 'Иван Иванов');
    });

    test('update edits participant name', () async {
      final repository = _InMemoryParticipantsRepository(
        participants: [
          Participant(id: '1', name: 'Иван Иванов'),
        ],
      );
      final useCase = UpdateParticipantUseCase(repository);

      final participant = await useCase.execute(
        participantId: '1',
        rawName: 'Иван Петров',
      );

      expect(participant.name, 'Иван Петров');
      expect(repository.participants.single.name, 'Иван Петров');
    });

    test('delete removes participant from active list', () async {
      final repository = _InMemoryParticipantsRepository(
        participants: [
          Participant(id: '1', name: 'Иван Иванов'),
        ],
      );
      final useCase = DeleteParticipantUseCase(repository);

      await useCase.execute('1');

      expect(repository.participants, isEmpty);
      expect(repository.deletedParticipantIds, ['1']);
    });

    test('empty name does not pass validation', () async {
      final repository = _InMemoryParticipantsRepository();
      final useCase = CreateParticipantUseCase(repository);

      expect(
        () => useCase.execute('   '),
        throwsA(
          isA<ParticipantsValidationException>().having(
            (error) => error.message,
            'message',
            'Введите имя участника.',
          ),
        ),
      );
    });
  });
}

final class _InMemoryParticipantsRepository implements ParticipantsRepository {
  _InMemoryParticipantsRepository({
    List<Participant>? participants,
  }) : _participants = [...?participants];

  final List<String> deletedParticipantIds = <String>[];
  final List<Participant> _participants;
  int _nextId = 1;

  List<Participant> get participants =>
      List<Participant>.unmodifiable(_participants);

  @override
  Future<Participant> create({
    required String name,
  }) async {
    final participant = Participant(
      id: (_nextId++).toString(),
      name: name,
    );
    _participants.add(participant);
    return participant;
  }

  @override
  Future<void> delete(String participantId) async {
    _participants.removeWhere((participant) => participant.id == participantId);
    deletedParticipantIds.add(participantId);
  }

  @override
  Future<List<Participant>> list() async {
    return [..._participants];
  }

  @override
  Future<Participant> update(Participant participant) async {
    final index = _participants.indexWhere(
      (candidate) => candidate.id == participant.id,
    );
    if (index != -1) {
      _participants[index] = participant;
    }
    return participant;
  }
}
